actions :create, :delete, :regenerate, :nothing
default_action :create

attribute :path, :kind_of => String, :name_attribute => true
attribute :format, :kind_of => Symbol, :default => :pem, :equal_to => [ :pem, :der ]
attribute :type, :kind_of => Symbol, :default => :rsa, :equal_to => [ :rsa, :dsa ] # TODO support :ec
attribute :public_key_path, :kind_of => String

# RSA and DSA
attribute :size, :kind_of => Integer, :default => 2048

# RSA-only
attribute :exponent, :kind_of => Integer # For RSA

# PEM-only
attribute :pass_phrase, :kind_of => String
attribute :cipher, :kind_of => String, :default => 'DES-EDE3-CBC', :equal_to => OpenSSL::Cipher.ciphers
