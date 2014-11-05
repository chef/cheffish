require 'cheffish'
require 'chef/resource/lwrp_base'

class Chef::Resource::ChefUser < Chef::Resource::LWRPBase
  self.resource_name = 'chef_user'

  actions :create, :delete, :nothing
  default_action :create

  # Grab environment from with_environment
  def initialize(*args)
    super
    chef_server run_context.cheffish.current_chef_server
  end

  # Client attributes
  attribute :name, :kind_of => String, :regex => Cheffish::NAME_REGEX, :name_attribute => true
  attribute :display_name, :kind_of => String
  attribute :admin, :kind_of => [TrueClass, FalseClass]
  attribute :email, :kind_of => String
  attribute :external_authentication_uid
  attribute :recovery_authentication_enabled, :kind_of => [TrueClass, FalseClass]
  attribute :password, :kind_of => String # Hmm.  There is no way to idempotentize this.
  #attribute :salt  # TODO server doesn't support sending or receiving these, but it's the only way to backup / restore a user
  #attribute :hashed_password
  #attribute :hash_type

  # Input key
  attribute :source_key # String or OpenSSL::PKey::*
  attribute :source_key_path, :kind_of => String
  attribute :source_key_pass_phrase

  # Output public key (if so desired)
  attribute :output_key_path, :kind_of => String
  attribute :output_key_format, :kind_of => Symbol, :default => :openssh, :equal_to => [ :pem, :der, :openssh ]

  # If this is set, client is not patchy
  attribute :complete, :kind_of => [TrueClass, FalseClass]

  attribute :raw_json, :kind_of => Hash
  attribute :chef_server, :kind_of => Hash

  # Proc that runs just before the resource executes.  Called with (resource)
  def before(&block)
    block ? @before = block : @before
  end

  # Proc that runs after the resource completes.  Called with (resource, json, private_key, public_key)
  def after(&block)
    block ? @after = block : @after
  end
end
