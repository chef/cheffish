require 'cheffish'
require 'cheffish/base_resource'
require 'chef/chef_fs/data_handler/container_data_handler'

class Chef
  class Resource
    class ChefContainer < Cheffish::BaseResource
      resource_name :chef_container

      # Grab environment from with_environment
      def initialize(*args)
        super
        chef_server run_context.cheffish.current_chef_server
      end

      property :name, :kind_of => String, :regex => Cheffish::NAME_REGEX, :name_attribute => true
      property :chef_server, :kind_of => Hash


      action :create do
        if !@current_exists
          converge_by "create container #{new_resource.name} at #{rest.url}" do
            rest.post("containers", normalize_for_post(new_json))
          end
        end
      end

      action :delete do
        if @current_exists
          converge_by "delete container #{new_resource.name} at #{rest.url}" do
            rest.delete("containers/#{new_resource.name}")
          end
        end
      end

      action_class.class_eval do
        def load_current_resource
          begin
            @current_exists = rest.get("containers/#{new_resource.name}")
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
          { 'containername' => :name, 'containerpath' => :name }
        end
      end
    end
  end
end
