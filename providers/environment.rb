def whyrun_supported?
  true
end

action :create do
  # TODO nice json diff of field internals for attrs and run list and such
  desired_json = new_environment_json
  different_fields = desired_json.keys.select { |key| desired_json[key] != current_json[key] }.to_a

  if current_resource_exists?
    if different_fields.size > 0
      description = [ "update environment #{new_resource.name} at #{rest.url}" ]
      description += different_fields.map { |field| "change #{field} from #{current_json[field].inspect} to #{new_json[field].inspect}" }
      converge_by description do
        rest.put("environments/#{new_resource.name}", normalize_for_put(desired_json))
        Chef::Log.info("#{new_resource} updated environment #{new_resource.name} at #{rest.url}")
      end
    end
  else
    description = [ "create environment #{new_resource.name} at #{rest.url}" ]
    description += different_fields.map { |field| "set #{field} to #{new_json[field].inspect}"}
    converge_by description do
      rest.post("environments", normalize_for_post(desired_json))
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

def new_environment_json
  result = new_json
  # Apply modifiers
  result['default_attributes'] = apply_modifiers(new_resource.default_attribute_modifiers, result['default_attributes'])
  result['override_attributes'] = apply_modifiers(new_resource.override_attribute_modifiers, result['override_attributes'])
  result
end

def apply_modifiers(modifiers, json)
  return json if !modifiers || modifiers.size == 0

  # If the attributes have nothing, set them to {} so we have something to add to
  if json
    json = Marshal.load(Marshal.dump(json)) # Deep copy
  else
    json = {}
  end

  modifiers.each do |path, value|
    path = [path] if !path.kind_of?(Array)
    parent = path[0..-2].inject(json) { |hash, path_part| hash ? hash[path_part] : nil }
    existing_value = parent ? parent[path[-1]] : nil

    if value.is_a?(Proc)
      value = value.call(existing_value)
    end
    if value == :delete
      parent.delete(path[-1]) if parent
      # TODO clean up parent chain if hash is completely emptied
    else
      if !parent
        # Create parent if necessary
        parent = path[0..-2].inject(json) do |hash, path_part|
          hash[path_part] = {} if !hash[path_part]
          hash[path_part]
        end
      end
      parent[path[-1]] = value
    end
  end
  json
end

#
# Helpers
#
# Gives us new_json, current_json, not_found_json, etc.
require 'chef/chef_fs/data_handler/environment_data_handler'

include Cheffish::ProviderHelpers

def resource_class
  Chef::Resource::CheffishEnvironment
end

def data_handler
  Chef::ChefFS::DataHandler::EnvironmentDataHandler.new
end

def keys
  %w(name description cookbook_versions default_attributes override_attributes)
end
