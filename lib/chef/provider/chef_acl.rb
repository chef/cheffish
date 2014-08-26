require 'cheffish/chef_provider_base'
require 'chef/resource/chef_acl'
require 'chef/chef_fs/data_handler/acl_data_handler'
require 'chef/chef_fs/parallelizer'

class Chef::Provider::ChefAcl < Cheffish::ChefProviderBase

  def whyrun_supported?
    true
  end

  action :create do
    paths, recursive = match_paths(new_resource.path)
    if paths.size == 0 && !new_resource.path.split('/').any? { |p| p == '*' }
      raise "Path #{new_resource.path} cannot have an ACL set on it!"
    end

    paths.each do |path|
      create_acl(path, recursive || new_resource.recursive)
    end
  end

  def create_acl(path, recursive)
    acl = acl_path(path)
    changed = false
    if acl
      current_json = current_acl(acl)
      if current_json
        Chef::ChefFS::Parallelizer.parallel_do(new_acl(acl)) do |permission, new_json|
          differences = json_differences(current_json[permission], new_json)

          if differences.size > 0
            changed = true
            description = [ "update #{permission} for acl #{new_resource.path} at #{rest.url}" ] + differences
            converge_by description do
              rest.put("#{acl}/#{permission}", { permission => new_json })
            end
          end
        end
      end
    end

    if recursive == true || (recursive == :on_change && (!acl || changed))
      children, error = list(path, '*')
      Chef::ChefFS::Parallelizer.parallel_do(children) do |child|
        next if child.split('/')[-1] == 'containers'
        create_acl(child, recursive)
      end
      # containers mess up our descent, so we do them last
      Chef::ChefFS::Parallelizer.parallel_do(children) do |child|
        next if child.split('/')[-1] != 'containers'
        create_acl(child, recursive)
      end

    end
  end

  def current_acl(acl_path)
    @current_acls ||= {}
    @current_acls[acl_path] ||= begin
      begin
        rest.get(acl_path)
      rescue Net::HTTPServerException => e
        unless e.response.code == '404' && new_resource.path.split('/').any? { |p| p == '*' }
          raise
        end
      end
    end
  end

  def new_acl(acl_path)
    result = new_resource.raw_json ? new_resource.raw_json.dup : {}
    if new_resource.complete
      result = Chef::ChefFS::DataHandler::AclDataHandler.new.normalize(result, nil)
    else
      # If resource is incomplete, use current json to fill any holes
      current_acl(acl_path).each do |permission, perm_hash|
        if !result[permission]
          result[permission] = perm_hash
        else
          result[permission] = result[permission].dup
          perm_hash.each do |type, actors|
            if !result[permission][type]
              result[permission][type] = actors
            else
              result[permission][type] = result[permission][type].dup
              result[permission][type] |= actors
            end
          end
        end
      end
      if new_resource.remove_rights
        new_resource.remove_rights.each_pair do |permission, perm_hash|
          perm_hash.each do |type, actors|
            result[permission] = result[permission].dup
            result[permission][type] = result[permission][type].dup
            result[permission][type] -= actors
          end
        end
      end
    end
    result
  end

  def load_current_resource
  end

  def match_paths(path)
    # Turn multiple slashes into one
    path = path.gsub(/[\/]+/, '/')
    if path[0] == '/'
      matches = [ '/' ]
    else
      matches = [ '' ]
    end

    # Split the path
    parts = path.split('/').select { |x| x != '' }.to_a

    # If there is a **, we will treat it special (and it's only supported in the
    # last bracket).
    if parts[-1] == '**'
      recursive = true
      parts = parts[0..-2]
    end

    # Descend until we find the starting path
    parts.each_with_index do |part, index|
      matches = Chef::ChefFS::Parallelizer.parallelize(matches) do |path|
        found, error = list(path, part)
        if error
          if parts[0..index-1].all? { |p| p != '*' }
            raise error
          end
          []
        else
          found
        end
      end.flatten(1).to_a
    end

    [ matches, recursive ]
  end

  def acl_path(path)
    parts = path.split('/').select { |x| x != '' }.to_a
    prefix = (path[0] == '/') ? '/' : ''

    case parts.size
    when 0
      # /, empty (relative root)
      # The root of the server has no publicly visible ACLs.  Only nodes/*, etc.
      if prefix == ''
        ::File.join('organizations', '_acl')
      end

    when 1
      # nodes, roles, etc.
      # The top level organizations and users containers have no publicly
      # visible ACLs.  Only nodes/*, etc.
      if prefix == ''
        ::File.join('containers', path, '_acl')
      end

    when 2
      # /organizations/NAME, /users/NAME, nodes/NAME, roles/NAME, etc.
      if prefix == '/' && parts[0] == 'organizations'
        ::File.join(path, 'organizations', '_acl')
      else
        ::File.join(path, '_acl')
      end

    when 3
      # /organizations/NAME/nodes, cookbooks/NAME/VERSION, etc.
      if prefix == '/'
        ::File.join('/', parts[0], parts[1], 'containers', parts[2], '_acl')
      else
        ::File.join(parts[0], parts[1], '_acl')
      end

    when 4
      # /organizations/NAME/nodes/NAME, cookbooks/NAME/VERSION/BLAH
      # /organizations/NAME/nodes/NAME, cookbooks/NAME/VERSION, etc.
      if prefix == '/'
        ::File.join(path, '_acl')
      else
        ::File.join(parts[0], parts[1], '_acl')
      end

    else
      # /organizations/NAME/cookbooks/NAME/VERSION/..., cookbooks/NAME/VERSION/A/B/...
      if prefix == '/'
        ::File.join('/', parts[0], parts[1], parts[2], parts[3], '_acl')
      else
        ::File.join(parts[0], parts[1], '_acl')
      end
    end
  end

  def list(path, child)
    # TODO make ChefFS understand top level organizations and stop doing this altogether.
    parts = path.split('/').select { |x| x != '' }.to_a
    absolute = (path[0] == '/')
    if absolute && parts[0] == 'organizations'
      return [ [], "ACLs cannot be set on children of #{path}" ] if parts.size > 3
    else
      return [ [], "ACLs cannot be set on children of #{path}" ] if parts.size > 1
    end

    error = nil

    if child == '*'
      case parts.size
      when 0
        # /*, *
        if absolute
          results = [ "/organizations", "/users" ]
        else
          results, error = rest_list("containers")
        end

      when 1
        # /organizations/*, /users/*, roles/*, nodes/*, etc.
        results, error = rest_list(path)
        if !error
          results = results.map { |result| ::File.join(path, result) }
        end

      when 2
        # /organizations/NAME/*
        results, error = rest_list(::File.join(path, 'containers'))
        if !error
          results = results.map { |result| ::File.join(path, result) }
        end

      when 3
        # /organizations/NAME/TYPE/*
        results, error = rest_list(path)
        if !error
          results = results.map { |result| ::File.join(path, result) }
        end
      end

    else
      if child == 'data_bags'
        parts.size == 0 || (parts.size == 2 && parts[0] == 'organizations')
        child = 'data'
      end

      if absolute
        results = [ ::File.join('/', parts[0..2], child) ]
      elsif parts.size == 0
        results = [ child ]
      else
        results = [ ::File.join(parts[0], child) ]
      end
    end

    [ results, error ]
  end

  def rest_list(path)
    begin
      [ rest.get(path).keys, nil ]
    rescue Net::HTTPServerException => e
      if e.response.code == '405' || e.response.code == '404'
        parts = path.split('/').select { |p| p != '' }.to_a

        # We KNOW we expect these to exist.  Other containers may or may not.
        unless (parts.size == 1 || (parts.size == 3 && parts[0] == 'organizations')) &&
          %w(clients containers cookbooks data environments groups nodes roles).include?(parts[-1])
          return [ [], "Cannot get list of #{path}: HTTP response code #{e.response.code}" ]
        end
      end
      raise
    end
  end
end
