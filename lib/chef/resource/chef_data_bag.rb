class Chef::Resource::ChefDataBag < Chef::Resource::LWRPBase
  self.resource_name = 'chef_data_bag'

  actions :create, :delete, :nothing
  default_action :create

  attribute :name, :kind_of => String, :regex => Cheffish::NAME_REGEX, :name_attribute => true

  # Proc to filter json.  We pass in the desired json before it is PUT/POST
  def filter(&block)
    block ? @filter = block : @filter
  end
end
