class Chef::Resource::ChefUser < Chef::Resource::LWRPBase
  self.resource_name = 'chef_user'

  actions :create, :delete, :regenerate_keys, :nothing
  default_action :create

  # Client attributes
  attribute :name, :kind_of => String, :regex => Cheffish::NAME_REGEX, :name_attribute => true
  attribute :admin, :kind_of => [TrueClass, FalseClass]
  attribute :email, :kind_of => String
  attribute :external_authentication_uid
  attribute :recovery_authentication_enabled, :kind_of => [TrueClass, FalseClass]
  attribute :password, :kind_of => String # Hmm.  There is no way to idempotentize this.
  #attribute :salt  # TODO server doesn't support sending or receiving these, but it's the only way to backup / restore a user
  #attribute :hashed_password
  #attribute :hash_type

  attribute :public_key_path, :kind_of => String
  attribute :private_key_path, :kind_of => String

  # If this is set, client is not patchy
  attribute :complete, :kind_of => [TrueClass, FalseClass]
  # If key_owner is set, our disk set of keys is considered canonical and keys on the server blown away.
  attribute :key_owner, :kind_of => [TrueClass, FalseClass]

  # Proc to filter json.  We pass in the desired json before it is PUT/POST
  attribute :filter, :kind_of => Proc
end
