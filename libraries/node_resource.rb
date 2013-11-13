class Chef::Resource::ChefNode < Chef::Resource::LWRPBase
  self.resource_name = 'chef_node'

  actions :create, :delete, :nothing
  default_action :create

  Cheffish.node_attributes(self)
end
