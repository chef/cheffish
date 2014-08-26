require 'cheffish/chef_provider_base'
require 'chef/resource/chef_acl'
require 'chef/chef_fs/data_handler/acl_data_handler'

class Chef::Provider::ChefAcl < Cheffish::ChefProviderBase

  def whyrun_supported?
    true
  end

  def self.acl_path(path)
    while path[0] == '/'
      absolute = true
      path = path[1..-1]
    end

    path = path.split('/')
    path[0] = 'data' if path[0] == 'data_bags'
    path[2] = 'data' if path[0] == 'organizations' && path[2] == 'data_bags'
    case path[0]
    when 'organizations'
      if path.size == 2
        "/organizations/#{path[1]}/organizations/_acl"
      else
        "/organizations/#{path[1]}/#{acl_path(path[2..-1].join('/'))}"
      end
    when 'users'
      "/users/#{path[1]}/_acl"
    when nil
      if absolute
        # Assume this is an open source server and get the org acl
        "organizations/_acl"
      else
        raise "Empty ACL passed as name to chef_acl '': not supported.  To set the organization ACL, use /"
      end
    else
      # chef_acl 'nodes' means "secure the nodes container"
      # chef_acl 'cookbooks/blah/1.1.0' means "secure cookbooks/blah"
      result = if path.size == 1
        "containers/#{path[0]}/_acl"
      else
        "#{path[0]}/#{path[1]}/_acl"
      end
      absolute ? "/#{result}" : result
    end
  end

  def acl_path
    ChefAcl.acl_path(new_resource.path)
  end

  action :create do
    new_json.each do |permission, json|
      differences = json_differences(current_json[permission], json)

      if differences.size > 0
        description = [ "update #{permission} for acl #{new_resource.path} at #{rest.url}" ] + differences
        converge_by description do
          rest.put("#{acl_path}/#{permission}", { permission => json })
        end
      end
    end
  end

  attr_reader :current_json

  def new_json
    @new_json ||= begin
      result = new_resource.raw_json || {}
      if new_resource.complete
        result = Chef::ChefFS::DataHandler::AclDataHandler.normalize(result)
      else
        # If resource is incomplete, use current json to fill any holes
        current_json.each do |permission, perm_hash|
          if !result[permission]
            result[permission] = perm_hash
          else
            perm_hash.each do |type, actors|
              if !result[permission][type]
                result[permission][type] = actors
              else
                result[permission][type] |= actors
              end
            end
          end
        end
      end
      result
    end
  end

  def load_current_resource
    @current_json = rest.get(acl_path)
  end
end
