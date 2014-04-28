require 'cheffish'
require 'chef/resource/lwrp_base'

class Chef::Resource::ChefClient < Chef::Resource::LWRPBase
  self.resource_name = 'chef_client'

  actions :create, :delete, :regenerate_keys, :nothing
  default_action :create

  def initialize(*args)
    super
    chef_server run_context.cheffish.current_chef_server
  end

  # Client attributes
  attribute :name, :kind_of => String, :regex => Cheffish::NAME_REGEX, :name_attribute => true
  attribute :admin, :kind_of => [TrueClass, FalseClass]
  attribute :validator, :kind_of => [TrueClass, FalseClass]

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
