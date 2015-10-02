require 'cheffish'
require 'chef_compat/resource'

class Chef
  class Resource
    class ChefClient < ChefCompat::Resource
      resource_name :chef_client

      allowed_actions :create, :delete, :regenerate_keys, :nothing
      default_action :create

      def initialize(*args)
        super
        chef_server run_context.cheffish.current_chef_server
      end

      # Client attributes
      property :name, Cheffish::NAME_REGEX, name_property: true
      property :admin, [true, false]
      property :validator, [true, false]

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
