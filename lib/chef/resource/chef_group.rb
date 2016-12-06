require "cheffish"
require "cheffish/base_resource"
require "chef/run_list/run_list_item"
require "chef/chef_fs/data_handler/group_data_handler"

class Chef
  class Resource
    class ChefGroup < Cheffish::BaseResource
      resource_name :chef_group

      property :group_name, Cheffish::NAME_REGEX, name_property: true
      property :users, ArrayType
      property :clients, ArrayType
      property :groups, ArrayType
      property :remove_users, ArrayType
      property :remove_clients, ArrayType
      property :remove_groups, ArrayType

      action :create do
        differences = json_differences(current_json, new_json)

        if current_resource_exists?
          if differences.size > 0
            description = [ "update group #{new_resource.group_name} at #{rest.url}" ] + differences
            converge_by description do
              rest.put("groups/#{new_resource.group_name}", normalize_for_put(new_json))
            end
          end
        else
          description = [ "create group #{new_resource.group_name} at #{rest.url}" ] + differences
          converge_by description do
            rest.post("groups", normalize_for_post(new_json))
          end
        end
      end

      action :delete do
        if current_resource_exists?
          converge_by "delete group #{new_resource.group_name} at #{rest.url}" do
            rest.delete("groups/#{new_resource.group_name}")
          end
        end
      end

      action_class.class_eval do
        def load_current_resource
          begin
            @current_resource = json_to_resource(rest.get("groups/#{new_resource.group_name}"))
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
          json["users"]   |= new_resource.users
          json["clients"] |= new_resource.clients
          json["groups"]  |= new_resource.groups
          json["users"]   -= new_resource.remove_users
          json["clients"] -= new_resource.remove_clients
          json["groups"]  -= new_resource.remove_groups
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
            "name" => :group_name,
            "groupname" => :group_name,
          }
        end
      end
    end
  end
end
