class Chef::Provider::ChefNode < Cheffish::ChefProviderBase

  def whyrun_supported?
    true
  end

  action :create do
    differences = json_differences(current_json, new_json)

    if current_resource_exists?
      if differences.size > 0
        description = [ "update node #{new_resource.name} at #{rest.url}" ] + differences
        converge_by description do
          rest.put("nodes/#{new_resource.name}", normalize_for_put(new_json))
        end
      end
    else
      description = [ "create node #{new_resource.name} at #{rest.url}" ] + differences
      converge_by description do
        rest.post("nodes", normalize_for_post(new_json))
      end
    end
  end

  action :delete do
    if current_resource_exists?
      converge_by "delete node #{new_resource.name} at #{rest.url}" do
        rest.delete("nodes/#{new_resource.name}")
      end
    end
  end

  def load_current_resource
    begin
      @current_resource = json_to_resource(rest.get("nodes/#{new_resource.name}"))
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
    json['run_list'] = apply_run_list_modifiers(new_resource.run_list_modifiers, new_resource.run_list_removers, json['run_list'])
    json['default'] = apply_modifiers(new_resource.default_modifiers, json['default'])
    json['normal'] = apply_modifiers(new_resource.normal_modifiers, json['normal'])
    json['override'] = apply_modifiers(new_resource.override_modifiers, json['override'])
    json['automatic'] = apply_modifiers(new_resource.automatic_modifiers, json['automatic'])
    json
  end

  #
  # Helpers
  #
  # Gives us new_json, current_json, not_found_json, etc.
  require 'chef/chef_fs/data_handler/node_data_handler'

  def resource_class
    Chef::Resource::ChefNode
  end

  def data_handler
    Chef::ChefFS::DataHandler::NodeDataHandler.new
  end

  def keys
    {
      'name' => :name,
      'chef_environment' => :chef_environment,
      'run_list' => :run_list,
      'default' => :default_attributes,
      'normal' => :normal_attributes,
      'override' => :override_attributes,
      'automatic' => :automatic_attributes
    }
  end
end
