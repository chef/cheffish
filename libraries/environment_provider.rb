class Chef::Provider::CheffishEnvironment < Cheffish::ChefProviderBase

  def whyrun_supported?
    true
  end

  action :create do
    # TODO nice json diff of field internals for attrs and run list and such
    different_fields = new_json.keys.select { |key| new_json[key] != current_json[key] }.to_a

    if current_resource_exists?
      if different_fields.size > 0
        description = [ "update environment #{new_resource.name} at #{rest.url}" ]
        description += different_fields.map { |field| "change #{field} from #{current_json[field].inspect} to #{new_json[field].inspect}" }
        converge_by description do
          rest.put("environments/#{new_resource.name}", normalize_for_put(new_json))
          Chef::Log.info("#{new_resource} updated environment #{new_resource.name} at #{rest.url}")
        end
      end
    else
      description = [ "create environment #{new_resource.name} at #{rest.url}" ]
      description += different_fields.map { |field| "set #{field} to #{new_json[field].inspect}"}
      converge_by description do
        rest.post("environments", normalize_for_post(new_json))
        Chef::Log.info("#{new_resource} created environment #{new_resource.name} at #{rest.url}")
      end
    end
  end

  action :delete do
    if current_resource_exists?
      converge_by "delete environment #{new_resource.name} at #{rest.url}" do
        rest.delete("environments/#{new_resource.name}")
        Chef::Log.info("#{new_resource} deleted environment #{new_resource.name} at #{rest.url}")
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

  def new_json
    @new_json ||= begin
      json = super
      # Apply modifiers
      json['default_attributes'] = apply_modifiers(new_resource.default_attribute_modifiers, json['default_attributes'])
      json['override_attributes'] = apply_modifiers(new_resource.override_attribute_modifiers, json['override_attributes'])
      json
    end
  end

  #
  # Helpers
  #
  # Gives us new_json, current_json, not_found_json, etc.
  require 'chef/chef_fs/data_handler/environment_data_handler'

  def resource_class
    Chef::Resource::CheffishEnvironment
  end

  def data_handler
    Chef::ChefFS::DataHandler::EnvironmentDataHandler.new
  end

  def keys
    %w(name description cookbook_versions default_attributes override_attributes)
  end

end