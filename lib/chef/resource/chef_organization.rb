require 'cheffish'
require 'chef/resource/lwrp_base'
require 'chef/run_list/run_list_item'

class Chef::Resource::ChefOrganization < Chef::Resource::LWRPBase
  self.resource_name = 'chef_organization'

  actions :create, :delete, :nothing
  default_action :create

  # Grab environment from with_environment
  def initialize(*args)
    super
    chef_server run_context.cheffish.current_chef_server
  end

  attribute :name, :kind_of => String, :regex => Cheffish::NAME_REGEX, :name_attribute => true
  attribute :full_name, :kind_of => String

  attribute :complete, :kind_of => [ TrueClass, FalseClass ]
  attribute :raw_json, :kind_of => Hash
  attribute :chef_server, :kind_of => Hash
end
