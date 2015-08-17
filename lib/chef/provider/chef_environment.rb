require 'cheffish/chef_provider_base'
require 'chef/resource/chef_environment'
require 'chef/chef_fs/data_handler/environment_data_handler'

class Chef::Provider::ChefEnvironment < Cheffish::ChefProviderBase
  provides :chef_environment

  def whyrun_supported?
    true
  end

  action :create do
    differences = json_differences(current_json, new_json)

    if current_resource_exists?
      if differences.size > 0
        description = [ "update environment #{new_resource.name} at #{rest.url}" ] + differences
        converge_by description do
          rest.put("environments/#{new_resource.name}", normalize_for_put(new_json))
        end
      end
    else
      description = [ "create environment #{new_resource.name} at #{rest.url}" ] + differences
      converge_by description do
        rest.post("environments", normalize_for_post(new_json))
      end
    end
  end

  action :delete do
    if current_resource_exists?
      converge_by "delete environment #{new_resource.name} at #{rest.url}" do
        rest.delete("environments/#{new_resource.name}")
      end
    end
  end

  def load_current_resource
    begin
      @current_resource = json_to_resource(rest.get("environments/#{new_resource.name}"))
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
    json['default_attributes'] = apply_modifiers(new_resource.default_attribute_modifiers, json['default_attributes'])
    json['override_attributes'] = apply_modifiers(new_resource.override_attribute_modifiers, json['override_attributes'])
    json
  end

  #
  # Helpers
  #

  def resource_class
    Chef::Resource::ChefEnvironment
  end

  def data_handler
    Chef::ChefFS::DataHandler::EnvironmentDataHandler.new
  end

  def keys
    {
      'name' => :name,
      'description' => :description,
      'cookbook_versions' => :cookbook_versions,
      'default_attributes' => :default_attributes,
      'override_attributes' => :override_attributes
    }
  end

end
