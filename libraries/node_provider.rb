class Chef::Provider::CheffishNode < Cheffish::ChefProviderBase

  def whyrun_supported?
    true
  end

  action :create do
    # TODO nice json diff of field internals for attrs and run list and such
    different_fields = new_json.keys.select { |key| new_json[key] != current_json[key] }.to_a

    if current_resource_exists?
      if different_fields.size > 0
        description = [ "update node #{new_resource.name} at #{rest.url}" ]
        description += different_fields.map { |field| "change #{field} from #{current_json[field].inspect} to #{new_json[field].inspect}" }
        converge_by description do
          rest.put("nodes/#{new_resource.name}", normalize_for_put(new_json))
        end
      end
    else
      description = [ "create node #{new_resource.name} at #{rest.url}" ]
      description += different_fields.map { |field| "set #{field} to #{new_json[field].inspect}"}
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

  def new_json
    @new_json ||= begin
      json = super
      # Apply modifiers
      json['run_list'] = apply_run_list_modifiers(new_resource.run_list_modifiers, new_resource.run_list_removers, json['run_list'])
      json['default'] = apply_modifiers(new_resource.default_modifiers, json['default'])
      json['normal'] = apply_modifiers(new_resource.normal_modifiers, json['normal'])
      json['override'] = apply_modifiers(new_resource.override_modifiers, json['override'])
      json['automatic'] = apply_modifiers(new_resource.automatic_modifiers, json['automatic'])
      json
    end
  end

  #
  # Helpers
  #
  # Gives us new_json, current_json, not_found_json, etc.
  require 'chef/chef_fs/data_handler/node_data_handler'

  def resource_class
    Chef::Resource::CheffishNode
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
