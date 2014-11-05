require 'openssl/cipher'
require 'chef/resource/lwrp_base'

class Chef::Resource::PrivateKey < Chef::Resource::LWRPBase
  self.resource_name = 'private_key'

  actions :create, :delete, :regenerate, :nothing
  default_action :create

  # Path to private key.  Set to :none to create the key in memory and not on disk.
  attribute :path, :kind_of => [ String, Symbol ], :name_attribute => true
  attribute :format, :kind_of => Symbol, :default => :pem, :equal_to => [ :pem, :der ]
  attribute :type, :kind_of => Symbol, :default => :rsa, :equal_to => [ :rsa, :dsa ] # TODO support :ec
  # These specify an optional public_key you can spit out if you want.
  attribute :public_key_path, :kind_of => String
  attribute :public_key_format, :kind_of => Symbol, :default => :openssh, :equal_to => [ :openssh, :pem, :der ]
  # Specify this if you want to copy another private key but give it a different format / password
  attribute :source_key
  attribute :source_key_path, :kind_of => String
  attribute :source_key_pass_phrase

  # RSA and DSA
  attribute :size, :kind_of => Integer, :default => 2048

  # RSA-only
  attribute :exponent, :kind_of => Integer # For RSA

  # PEM-only
  attribute :pass_phrase, :kind_of => String
  attribute :cipher, :kind_of => String, :default => 'DES-EDE3-CBC', :equal_to => OpenSSL::Cipher.ciphers

  # Set this to regenerate the key if it does not have the desired characteristics (like size, type, etc.)
  attribute :regenerate_if_different, :kind_of => [TrueClass, FalseClass]

  # Proc that runs after the resource completes.  Called with (resource, private_key)
  def after(&block)
    block ? @after = block : @after
  end

  # We are not interested in Chef's cloning behavior here.
  def load_prior_resource(*args)
    Chef::Log.debug("Overloading #{resource_name}.load_prior_resource with NOOP")
  end
end
