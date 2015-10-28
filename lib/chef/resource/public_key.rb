require 'openssl/cipher'
require 'chef_compat/resource'

class Chef
  class Resource
    class PublicKey < ChefCompat::Resource
      resource_name :public_key

      allowed_actions :create, :delete, :nothing
      default_action :create

      property :path, :kind_of => String, :name_attribute => true
      property :format, :kind_of => Symbol, :default => :openssh, :equal_to => [ :pem, :der, :openssh ]

      property :source_key
      property :source_key_path, :kind_of => String
      property :source_key_pass_phrase

      # We are not interested in Chef's cloning behavior here.
      def load_prior_resource(*args)
        Chef::Log.debug("Overloading #{resource_name}.load_prior_resource with NOOP")
      end
    end
  end
end
