class Chef::Resource::ChefDataBag < Chef::Resource::LWRPBase
  self.resource_name = 'chef_data_bag'

  actions :create, :delete, :nothing
  default_action :create

  attribute :name, :kind_of => String, :regex => Cheffish::NAME_REGEX, :name_attribute => true
end