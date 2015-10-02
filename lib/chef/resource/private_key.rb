require 'openssl/cipher'
require 'chef_compat/resource'

class Chef
  class Resource
    class PrivateKey < ChefCompat::Resource
      use_automatic_resource_name

      allowed_actions :create, :delete, :regenerate, :nothing
      default_action :create

      # Path to private key.  Set to :none to create the key in memory and not on disk.
      property :path, [ String, :none ], name_property: true
      property :format, [ :pem, :der ], default: :pem
      property :type, [ :rsa, :dsa ], default: :rsa # TODO support :ec
      # These specify an optional public_key you can spit out if you want.
      property :public_key_path, [ String, nil ]
      property :public_key_format, [ :openssh, :pem, :der ], default: :openssh
      # Specify this if you want to copy another private key but give it a different format / password
      property :source_key
      property :source_key_path, String
      property :source_key_pass_phrase

      # RSA and DSA
      property :size, Integer, default: 2048

      # RSA-only
      property :exponent, Integer # For RSA

      # PEM-only
      property :pass_phrase, String
      property :cipher, OpenSSL::Cipher.ciphers, default: 'DES-EDE3-CBC'

      # Set this to regenerate the key if it does not have the desired characteristics (like size, type, etc.)
      property :regenerate_if_different, [ true, false ]

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
