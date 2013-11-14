class Chef::Resource::ChefClient < Chef::Resource::LWRPBase
  self.resource_name = 'chef_client'

  actions :create, :delete, :regenerate_keys, :nothing
  default_action :create

  # Client attributes
  attribute :name, :kind_of => String, :regex => Cheffish::NAME_REGEX, :name_attribute => true
  attribute :admin, :kind_of => [TrueClass, FalseClass]
  attribute :validator, :kind_of => [TrueClass, FalseClass]

  attribute :public_key_path, :kind_of => String
  attribute :private_key, :kind_of => [ String, Proc ]
  attribute :private_key_path, :kind_of => String

  # If this is set, client is not patchy
  attribute :complete, :kind_of => [TrueClass, FalseClass]
  # If key_owner is set, our disk set of keys is considered canonical and keys on the server blown away.
  attribute :key_owner, :kind_of => [TrueClass, FalseClass]

  # Proc to filter json.  We pass in the desired json before it is PUT/POST
  attribute :filter, :kind_of => Proc

  # Proc that runs just before the resource executes.  Called with (resource)
  attribute :before, :kind_of => Proc

  # Proc that runs after the resource completes.  Called with (resource, json, private_key, public_key)
  attribute :after, :kind_of => Proc
end
