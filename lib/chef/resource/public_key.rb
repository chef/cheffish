require 'openssl/cipher'
require 'chef_compat/resource'

class Chef
  class Resource
    class PublicKey < ChefCompat::Resource
      use_automatic_resource_name

      allowed_actions :create, :delete, :nothing
      default_action :create

      property :path, String, name_property: true
      property :format, [ :pem, :der, :openssh ], default: :openssh

      property :source_key
      property :source_key_path, String
      property :source_key_pass_phrase

      # We are not interested in Chef's cloning behavior here.
      def load_prior_resource(*args)
        Chef::Log.debug("Overloading #{resource_name}.load_prior_resource with NOOP")
      end
    end
  end
end
