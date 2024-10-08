require_relative "../../cheffish"
require_relative "../../cheffish/base_resource"

class Chef
  class Resource
    class ChefDataBag < Cheffish::BaseResource
      provides :chef_data_bag, target_mode: true

      property :data_bag_name, Cheffish::NAME_REGEX, name_property: true

      action :create do
        unless current_resource_exists?
          converge_by "create data bag #{new_resource.data_bag_name} at #{rest.url}" do
            rest.post("data", { "name" => new_resource.data_bag_name })
          end
        end
      end

      action :delete do
        if current_resource_exists?
          converge_by "delete data bag #{new_resource.data_bag_name} at #{rest.url}" do
            rest.delete("data/#{new_resource.data_bag_name}")
          end
        end
      end

      action_class.class_eval do
        def load_current_resource
          @current_resource = json_to_resource(rest.get("data/#{new_resource.data_bag_name}"))
        rescue Net::HTTPClientException => e
          if e.response.code == "404"
            @current_resource = not_found_resource
          else
            raise
          end
        end

        #
        # Helpers
        #
        # Gives us new_json, current_json, not_found_json, etc.

        def resource_class
          Chef::Resource::ChefDataBag
        end

        def json_to_resource(json)
          Chef::Resource::ChefDataBag.new(json["name"], run_context)
        end
      end
    end
  end
end
