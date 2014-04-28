require 'cheffish'
require 'chef/resource/lwrp_base'

class Chef::Resource::ChefNode < Chef::Resource::LWRPBase
  self.resource_name = 'chef_node'

  actions :create, :delete, :nothing
  default_action :create

  # Grab environment from with_environment
  def initialize(*args)
    super
    chef_environment run_context.cheffish.current_environment
    chef_server run_context.cheffish.current_chef_server
  end

  Cheffish.node_attributes(self)
end
