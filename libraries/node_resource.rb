class Chef::Resource::ChefNode < Chef::Resource::LWRPBase
  self.resource_name = 'chef_node'

  # Grab environment from with_environment
  def initialize(*args)
    super
    if Cheffish.enclosing_environment
      chef_environment Cheffish.enclosing_environment
    end
  end

  actions :create, :delete, :nothing
  default_action :create

  Cheffish.node_attributes(self)

  # Proc to filter json.  We pass in the desired json before it is PUT/POST
  def filter(&block)
    block ? @filter = block : @filter
  end
end
