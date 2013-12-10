require 'cheffish'
require 'chef/resource/lwrp_base'
require 'cheffish/provider/chef_node'

module Cheffish
  module Resource
    class ChefNode < Chef::Resource::LWRPBase
      self.resource_name = 'chef_node'
      provides :chef_node
      def provider
        Cheffish::Provider::ChefNode
      end

      actions :create, :delete, :nothing
      default_action :create

      # Grab environment from with_environment
      def initialize(*args)
        super
        chef_environment Cheffish.enclosing_environment
        chef_server Cheffish.enclosing_chef_server
      end

      Cheffish.node_attributes(self)
    end
  end
end
