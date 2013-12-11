require 'openssl/cipher'
require 'chef/resource/lwrp_base'

class Chef::Resource::PrivateKey < Chef::Resource::LWRPBase
  self.resource_name = 'private_key'

  actions :create, :delete, :regenerate, :nothing
  default_action :create

  attribute :path, :kind_of => String, :name_attribute => true
  attribute :format, :kind_of => Symbol, :default => :pem, :equal_to => [ :pem, :der ]
  attribute :type, :kind_of => Symbol, :default => :rsa, :equal_to => [ :rsa, :dsa ] # TODO support :ec
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
end