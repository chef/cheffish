require 'openssl/cipher'
require 'chef_compat/resource'

class Chef
  class Resource
    class PrivateKey < ChefCompat::Resource
      resource_name :private_key

      allowed_actions :create, :delete, :regenerate, :nothing
      default_action :create

      # Path to private key.  Set to :none to create the key in memory and not on disk.
      property :path, :kind_of => [ String, Symbol ], :name_attribute => true
      property :format, :kind_of => Symbol, :default => :pem, :equal_to => [ :pem, :der ]
      property :type, :kind_of => Symbol, :default => :rsa, :equal_to => [ :rsa, :dsa ] # TODO support :ec
      # These specify an optional public_key you can spit out if you want.
      property :public_key_path, :kind_of => String
      property :public_key_format, :kind_of => Symbol, :default => :openssh, :equal_to => [ :openssh, :pem, :der ]
      # Specify this if you want to copy another private key but give it a different format / password
      property :source_key
      property :source_key_path, :kind_of => String
      property :source_key_pass_phrase

      # RSA and DSA
      property :size, :kind_of => Integer, :default => 2048

      # RSA-only
      property :exponent, :kind_of => Integer # For RSA

      # PEM-only
      property :pass_phrase, :kind_of => String
      property :cipher, :kind_of => String, :default => 'DES-EDE3-CBC', :equal_to => OpenSSL::Cipher.ciphers

      # Set this to regenerate the key if it does not have the desired characteristics (like size, type, etc.)
      property :regenerate_if_different, :kind_of => [TrueClass, FalseClass]

      # Proc that runs after the resource completes.  Called with (resource, private_key)
      def after(&block)
        block ? @after = block : @after
      end

      # We are not interested in Chef's cloning behavior here.
      def load_prior_resource(*args)
        Chef::Log.debug("Overloading #{resource_name}.load_prior_resource with NOOP")
      end
    end
  end
end
