require "cheffish"
require "cheffish/base_resource"
require "chef/chef_fs/data_handler/container_data_handler"

class Chef
  class Resource
    class ChefContainer < Cheffish::BaseResource
      resource_name :chef_container

      property :chef_container_name, Cheffish::NAME_REGEX, name_property: true

      action :create do
        if !@current_exists
          converge_by "create container #{new_resource.chef_container_name} at #{rest.url}" do
            rest.post("containers", normalize_for_post(new_json))
          end
        end
      end

      action :delete do
        if @current_exists
          converge_by "delete container #{new_resource.chef_container_name} at #{rest.url}" do
            rest.delete("containers/#{new_resource.chef_container_name}")
          end
        end
      end

      action_class.class_eval do
        def load_current_resource
          begin
            @current_exists = rest.get("containers/#{new_resource.chef_container_name}")
          rescue Net::HTTPServerException => e
            if e.response.code == "404"
              @current_exists = false
            else
              raise
            end
          end
        end

        def new_json
          {}
        end

        def data_handler
          Chef::ChefFS::DataHandler::ContainerDataHandler.new
        end

        def keys
          { "containername" => :chef_container_name, "containerpath" => :chef_container_name }
        end
      end
    end
  end
end
