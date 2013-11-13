# Due to the order in which things are loaded, we have to predeclare this class
class Chef::Resource::ChefNode < Chef::Resource::LWRPBase
end

class Chef::Resource::Machine < Chef::Resource::LWRPBase
  self.resource_name = 'machine'

  actions :create, :delete, :nothing
  default_action :create

  Cheffish.node_attributes(self)

  attribute :bootstrapper, :kind_of => Symbol
  attribute :public_key_path, :kind_of => String
  attribute :private_key_path, :kind_of => String
end
