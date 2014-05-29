require 'cheffish'
require 'cheffish/resource_base'

class Chef::Resource::ChefNode < Cheffish::ResourceBase
  actions :create, :delete, :nothing
  default_action :create

  # Grab environment from with_environment
  def initialize(*args)
    super
    chef_environment run_context.cheffish.current_environment
  end

  Cheffish.node_attributes(self)
end
