require 'cheffish'
require 'chef_compat/resource'

class Chef
  class Resource
    class ChefUser < ChefCompat::Resource
      use_automatic_resource_name

      allowed_actions :create, :delete, :nothing
      default_action :create

      # Grab environment from with_environment
      def initialize(*args)
        super
        chef_server run_context.cheffish.current_chef_server
      end

      # Client attributes
      property :name, Cheffish::NAME_REGEX, name_property: true
      property :display_name, String
      property :admin, [true, false]
      property :email, String
      property :external_authentication_uid
      property :recovery_authentication_enabled, [true, false]
      property :password, String # Hmm.  There is no way to idempotentize this.
      #property :salt  # TODO server doesn't support sending or receiving these, but it's the only way to backup / restore a user
      #property :hashed_password
      #property :hash_type

      # Input key
      property :source_key # String or OpenSSL::PKey::*
      property :source_key_path, String
      property :source_key_pass_phrase

      # Output public key (if so desired)
      property :output_key_path, String
      property :output_key_format, [ :pem, :der, :openssh ], default: :openssh

      # If this is set, client is not patchy
      property :complete, [true, false]

      property :raw_json, Hash
      property :chef_server, Hash

      # Proc that runs just before the resource executes.  Called with (resource)
      def before(&block)
        block ? @before = block : @before
      end

      # Proc that runs after the resource completes.  Called with (resource, json, private_key, public_key)
      def after(&block)
        block ? @after = block : @after
      end
    end
  end
end
