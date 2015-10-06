require 'cheffish'
require 'cheffish/chef_resource_base'
require 'chef/run_list/run_list_item'
require 'cheffish/resource/chef_group'
require 'chef/chef_fs/data_handler/group_data_handler'

module Cheffish
  module Resource
    class ChefGroup < Cheffish::ChefResourceBase
      use_automatic_resource_name

      # Grab environment from with_environment
      def initialize(*args)
        super
        @users = []
        @clients = []
        @groups = []
        @remove_users = []
        @remove_clients = []
        @remove_groups = []
      end

      property :name, Cheffish::NAME_REGEX, name_property: true
      def users(*users)
        users.size == 0 ? @users : (@users |= users.flatten)
      end
      def clients(*clients)
        clients.size == 0 ? @clients : (@clients |= clients.flatten)
      end
      def groups(*groups)
        groups.size == 0 ? @groups : (@groups |= groups.flatten)
      end
      def remove_users(*remove_users)
        remove_users.size == 0 ? @remove_users : (@remove_users |= remove_users.flatten)
      end
      def remove_clients(*remove_clients)
        remove_clients.size == 0 ? @remove_clients : (@remove_clients |= remove_clients.flatten)
      end
      def remove_groups(*remove_groups)
        remove_groups.size == 0 ? @remove_groups : (@remove_groups |= remove_groups.flatten)
      end

      # Specifies that this is a complete specification for the environment (i.e. attributes you don't specify will be
      # reset to their defaults)
      property :complete, Boolean

      property :raw_json, Hash
      property :chef_server, Hash

      action :create do
        differences = json_differences(current_json, new_json)

        if current_resource_exists?
          if differences.size > 0
            description = [ "update group #{new_resource.name} at #{rest.url}" ] + differences
            converge_by description do
              rest.put("groups/#{new_resource.name}", normalize_for_put(new_json))
            end
          end
        else
          description = [ "create group #{new_resource.name} at #{rest.url}" ] + differences
          converge_by description do
            rest.post("groups", normalize_for_post(new_json))
          end
        end
      end

      action :delete do
        if current_resource_exists?
          converge_by "delete group #{new_resource.name} at #{rest.url}" do
            rest.delete("groups/#{new_resource.name}")
          end
        end
      end

      # Action helpers
      action_class.class_eval do
        def load_current_resource
          begin
            @current_resource = json_to_resource(rest.get("groups/#{new_resource.name}"))
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
          json['users']   |= new_resource.users
          json['clients'] |= new_resource.clients
          json['groups']  |= new_resource.groups
          json['users']   -= new_resource.remove_users
          json['clients'] -= new_resource.remove_clients
          json['groups']  -= new_resource.remove_groups
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
            'name' => :name,
            'groupname' => :name
          }
        end
      end
    end
  end
end
