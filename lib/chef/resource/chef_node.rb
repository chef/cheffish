require 'cheffish'
require 'chef_compat/resource'

class Chef
  class Resource
    class ChefNode < ChefCompat::Resource
      resource_name :chef_node

      allowed_actions :create, :delete, :nothing
      default_action :create

      # Grab environment from with_environment
      def initialize(*args)
        super
        chef_environment run_context.cheffish.current_environment
        chef_server run_context.cheffish.current_chef_server
      end

      Cheffish.node_attributes(self)
    end
  end
end
