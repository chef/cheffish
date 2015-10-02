require 'cheffish'
require 'chef_compat/resource'
require 'chef/run_list/run_list_item'

class Chef
  class Resource
    class ChefGroup < ChefCompat::Resource
      resource_name :chef_group

      allowed_actions :create, :delete, :nothing
      default_action :create

      # Grab environment from with_environment
      def initialize(*args)
        super
        chef_server run_context.cheffish.current_chef_server
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
      property :complete, [true, false]

      property :raw_json, Hash
      property :chef_server, Hash
    end
  end
end
