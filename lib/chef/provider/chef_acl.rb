require 'cheffish/chef_provider_base'
require 'chef/resource/chef_acl'
require 'chef/chef_fs/data_handler/acl_data_handler'

class Chef::Provider::ChefAcl < Cheffish::ChefProviderBase

  def whyrun_supported?
    true
  end

  def acl_paths
    @acl_paths ||= begin
      paths, recursive = match_paths(new_resource.path)
      @recursive = new_resource.recursive || recursive

      results = []
      paths.each do |path|
        result = acl_path(path)
        results << result if result
      end
      results
    end
  end

  def recursive
    if !@recursive
      acl_paths
    end
    @recursive
  end

  action :create do
    acl_paths.each do |acl_path|
      new_acl(acl_path).each do |permission, json|
        differences = json_differences(current_acl(acl_path)[permission], json)

        if differences.size > 0
          description = [ "update #{permission} for acl #{new_resource.path} at #{rest.url}" ] + differences
          converge_by description do
            rest.put("#{acl_path}/#{permission}", { permission => json })
          end
        end
      end
    end
  end

  def current_acl(acl_path)
    @current_acls[acl_path] || rest.get(acl_path)
  end

  def new_acl(acl_path)
    result = new_resource.raw_json ? new_resource.raw_json.dup : {}
    if new_resource.complete
      result = Chef::ChefFS::DataHandler::AclDataHandler.normalize(result)
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
    end
    result
  end

  def load_current_resource
    @current_acls = {}
    acl_paths.each { |acl_path| @current_acls[acl_path] = rest.get(acl_path) }
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
    parts.each do |part|
      new_matches = []
      matches.each do |path|
        new_matches += list(path, part)
      end
      matches = new_matches
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
        ::File.join('containers', path, '_acl').join('/')
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
      return [] if parts.size > 3
    else
      return [] if parts.size > 1
    end

    if child == '*'
      results = case parts.size
      when 0
        # /*, *
        if absolute
          [ "/organizations", "/users" ]
        else
          rest_list("containers")
        end

      when 1
        # /organizations/*, /users/*, roles/*, nodes/*, etc.
        rest_list(path).map { |result| ::File.join(path, result) }

      when 2
        # /organizations/NAME/*
        if absolute
          rest_list(::File.join(path, 'containers')).map { |result| ::File.join(path, result) }
        end

      when 3
        # /organizations/NAME/TYPE/*
        if absolute
          rest_list(path).map { |result| ::File.join(path, result) }
        end
      end
      results || []

    else
      if child == 'data_bags'
        parts.size == 0 || (parts.size == 2 && parts[0] == 'organizations')
        child = 'data'
      end

      if absolute
        [ ::File.join('/', parts[0..2], child) ]
      elsif parts.size == 0
        [ child ]
      else
        [ ::File.join(parts[0], child) ]
      end
    end
  end

  def rest_list(path)
    rest.get(path).keys
  end
end
