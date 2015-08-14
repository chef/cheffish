require 'cheffish/chef_provider_base'
require 'chef/resource/chef_group'
require 'chef/chef_fs/data_handler/group_data_handler'

class Chef::Provider::ChefGroup < Cheffish::ChefProviderBase
  provides :chef_group

  def whyrun_supported?
    true
  end

  action :create do
    differences = json_differences(current_json, new_json)

    if current_resource_exists?
      if differences.size > 0
        description = [ "update group #{new_resource.name} at #{rest.url}" ] + differences
        converge_by description do
          rest.put("groups/#{new_resource.name}", normalize_for_put(new_json))
        end
      end
    else
      description = [ "create group #{new_resource.name} at #{rest.url}" ] + differences
      converge_by description do
        rest.post("groups", normalize_for_post(new_json))
      end
    end
  end

  action :delete do
    if current_resource_exists?
      converge_by "delete group #{new_resource.name} at #{rest.url}" do
        rest.delete("groups/#{new_resource.name}")
      end
    end
  end

  def load_current_resource
    begin
      @current_resource = json_to_resource(rest.get("groups/#{new_resource.name}"))
    rescue Net::HTTPServerException => e
      if e.response.code == "404"
        @current_resource = not_found_resource
      else
        raise
      end
    end
  end

  def augment_new_json(json)
    # Apply modifiers
    json['users']   |= new_resource.users
    json['clients'] |= new_resource.clients
    json['groups']  |= new_resource.groups
    json['users']   -= new_resource.remove_users
    json['clients'] -= new_resource.remove_clients
    json['groups']  -= new_resource.remove_groups
    json
  end

  #
  # Helpers
  #

  def resource_class
    Chef::Resource::ChefGroup
  end

  def data_handler
    Chef::ChefFS::DataHandler::GroupDataHandler.new
  end

  def keys
    {
      'name' => :name,
      'groupname' => :name
    }
  end
end
