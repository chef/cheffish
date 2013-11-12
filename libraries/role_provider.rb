class Chef::Provider::ChefRole < Cheffish::ChefProviderBase

  def whyrun_supported?
    true
  end

  action :create do
    differences = json_differences(current_json, new_json)

    if current_resource_exists?
      if differences.size > 0
        description = [ "update role #{new_resource.name} at #{rest.url}" ] + differences
        converge_by description do
          rest.put("roles/#{new_resource.name}", normalize_for_put(new_json))
        end
      end
    else
      description = [ "create role #{new_resource.name} at #{rest.url}" ] + differences
      converge_by description do
        rest.post("roles", normalize_for_post(new_json))
      end
    end
  end

  action :delete do
    if current_resource_exists?
      converge_by "delete role #{new_resource.name} at #{rest.url}" do
        rest.delete("roles/#{new_resource.name}")
      end
    end
  end

  def load_current_resource
    begin
      @current_resource = json_to_resource(rest.get("roles/#{new_resource.name}"))
    rescue Net::HTTPServerException => e
      if e.response.code == "404"
        @current_resource = not_found_resource
      else
        raise
      end
    end
  end

  def new_json
    @new_json ||= begin
      json = super
      # Apply modifiers
      json['run_list'] = apply_run_list_modifiers(new_resource.run_list_modifiers, new_resource.run_list_removers, json['run_list'])
      json['default_attributes'] = apply_modifiers(new_resource.default_attribute_modifiers, json['default_attributes'])
      json['override_attributes'] = apply_modifiers(new_resource.override_attribute_modifiers, json['override_attributes'])
      json
    end
  end

  #
  # Helpers
  #
  # Gives us new_json, current_json, not_found_json, etc.
  require 'chef/chef_fs/data_handler/role_data_handler'

  def resource_class
    Chef::Resource::ChefRole
  end

  def data_handler
    Chef::ChefFS::DataHandler::RoleDataHandler.new
  end

  def keys
    {
      'name' => :name,
      'description' => :description,
      'run_list' => :run_list,
      'env_run_lists' => :env_run_lists,
      'default_attributes' => :default_attributes,
      'override_attributes' => :override_attributes
    }
  end
end
