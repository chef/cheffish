require "cheffish"
require "cheffish/base_resource"
require "chef/chef_fs/data_handler/node_data_handler"
require "cheffish/node_properties"

class Chef
  class Resource
    class ChefNode < Cheffish::BaseResource
      resource_name :chef_node

      include Cheffish::NodeProperties

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

      action_class.class_eval do
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
          # Preserve tags even if "attributes" was overwritten directly
          json["normal"]["tags"] = current_json["normal"]["tags"] unless json["normal"]["tags"]
          # Apply modifiers
          json["run_list"] = apply_run_list_modifiers(new_resource.run_list_modifiers, new_resource.run_list_removers, json["run_list"])
          json["normal"] = apply_modifiers(new_resource.attribute_modifiers, json["normal"])
          # Preserve default/override/automatic even when "complete true"
          json["default"] = current_json["default"]
          json["override"] = current_json["override"]
          json["automatic"] = current_json["automatic"]
          json
        end

        #
        # Helpers
        #

        def resource_class
          Chef::Resource::ChefNode
        end

        def data_handler
          Chef::ChefFS::DataHandler::NodeDataHandler.new
        end

        def keys
          {
            "name" => :name,
            "chef_environment" => :chef_environment,
            "run_list" => :run_list,
            "normal" => :attributes,
          }
        end
      end
    end
  end
end
