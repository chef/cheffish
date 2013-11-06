actions :create, :delete, :regenerate_key, :nothing
default_action :create

# Client attributes
attribute :name, :kind_of => String, :regex => Cheffish::NAME_REGEX, :name_attribute => true
attribute :admin, :kind_of => [TrueClass, FalseClass]
attribute :validator, :kind_of => [TrueClass, FalseClass]

attribute :public_key_path, :kind_of => String
attribute :private_key_path, :kind_of => String

# If this is set, client is not patchy
attribute :complete, :kind_of => [TrueClass, FalseClass]
# If key_owner is set, our disk set of keys is considered canonical and keys on the server blown away.
attribute :key_owner, :kind_of => [TrueClass, FalseClass]
