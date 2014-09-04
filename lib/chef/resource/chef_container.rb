require 'cheffish'
require 'chef/resource/lwrp_base'

class Chef::Resource::ChefContainer < Chef::Resource::LWRPBase
  self.resource_name = 'chef_container'

  actions :create, :delete, :nothing
  default_action :create

  # Grab environment from with_environment
  def initialize(*args)
    super
    chef_server run_context.cheffish.current_chef_server
  end

  attribute :name, :kind_of => String, :regex => Cheffish::NAME_REGEX, :name_attribute => true
  attribute :chef_server, :kind_of => Hash
end
