require 'chef/provider/lwrp_base'
require 'openssl/pkey/rsa'

class Chef::Provider::PrivateKey < Chef::Provider::LWRPBase

  action :create do
    create_keys(false)
  end

  action :regenerate do
    create_keys(true)
  end

  action :delete do
    if Array(current_resource.action) == [ :create ]
      converge_by "delete private key #{new_resource.path}" do
        File.unlink(new_resource.path)
      end
    end
    if current_resource.public_key_path && File.exist?(new_resource.public_key_path)
      converge_by "delete public key #{new_resource.public_key_path}" do
        File.unlink(new_resource.public_key_path)
      end
    end
  end

  require 'openssl'

  def whyrun_supported?
    true
  end

  def create_keys(regenerate)
    #
    # Create private key file
    #
    new_private_key = nil
    if Array(current_resource.action) == [ :delete ] || regenerate ||
      (new_resource.regenerate_if_different &&
        (current_resource.size != new_resource.size ||
         current_resource.type != new_resource.type))
      action = ::File.exists?(current_resource.path) ? "overwrite" : "create"
      converge_by "#{action} #{new_resource.type} private key #{new_resource.path} (#{new_resource.size} bits#{new_resource.pass_phrase ? ", #{new_resource.cipher} password" : ""})" do
        case new_resource.type
        when :rsa
          if new_resource.exponent
            new_private_key = OpenSSL::PKey::RSA.generate(new_resource.size, new_resource.exponent)
          else
            new_private_key = OpenSSL::PKey::RSA.generate(new_resource.size)
          end
        when :dsa
          new_private_key = OpenSSL::PKey::DSA.generate(new_resource.size)
        end

        create_private_key(new_private_key)
      end
    else
      # Warn if existing key has different characteristics than expected
      if current_resource.size != new_resource.size
        Chef::Log.warn("Mismatched key size!  #{current_resource.path} is #{current_resource.size} bytes, desired is #{new_resource.size} bytes.  Use action :regenerate to force key regeneration.")
      elsif current_resource.type != new_resource.type
        Chef::Log.warn("Mismatched key size!  #{current_resource.path} is #{current_resource.size} bytes, desired is #{new_resource.size} bytes.  Use action :regenerate to force key regeneration.")
      end

      if current_resource.format != new_resource.format
        converge_by "change format of #{new_resource.type} private key #{new_resource.path} from #{current_resource.format} to #{new_resource.format}" do
          create_private_key(current_private_key)
        end
      end
    end

    # Read in the existing private key if we didn't change it
    new_private_key = current_private_key if !new_private_key

    #
    # Create public key file
    #
    if new_resource.public_key_path
      if !current_resource.public_key_path || # If it's new ...
         new_resource.format != current_public_key_format || # Or the format has changed
         (new_private_key && new_private_key.public_key.to_s != current_public_key.to_s) # Or the public key has changed
        action = current_resource.public_key_path ? "overwrite" : "create"
        converge_by "#{action} #{new_resource.type} public key #{new_resource.public_key_path}" do
          create_public_key(new_private_key.public_key)
        end
      end
    end
  end

  def create_private_key(pkey)
    case new_resource.format
    when :pem
      if new_resource.pass_phrase
        private_key_contents = pkey.to_pem(OpenSSL::Cipher.new(new_resource.cipher), new_resource.pass_phrase)
      else
        private_key_contents = pkey.to_pem
      end
    when :der
      private_key_contents = pkey.to_der
    end

    ::File.open(new_resource.path, 'w') do |file|
      file.write(private_key_contents)
    end
  end

  def create_public_key(pkey)
    case new_resource.format
    when :pem
      public_key_contents = pkey.public_key.to_pem
    when :der
      public_key_contents = pkey.public_key.to_der
    end

    ::File.open(new_resource.public_key_path, 'w') do |file|
      file.write(public_key_contents)
    end
  end

  def format_of(key_contents)
    if key_contents.start_with?('-----BEGIN ')
      :pem
    else
      :der
    end
  end

  def type_of(pkey)
    case pkey.class
    when OpenSSL::PKey::RSA
      :rsa
    when OpenSSL::PKey::DSA
      :dsa
    end
  end

  attr_reader :current_private_key
  attr_reader :current_public_key
  attr_reader :current_public_key_format

  def load_current_resource
    if ::File.exist?(new_resource.path)
      # Detect private key info
      private_key_contents = ::File.read(new_resource.path)
      resource = Chef::Resource::PrivateKey.new(new_resource.path)
      begin
        @current_private_key = OpenSSL::PKey.read(private_key_contents, new_resource.pass_phrase)
        resource.size current_private_key.n.num_bytes * 8
        #resource.pass_phrase
        #resource.cipher?  Not sure how to get this from pem file
        resource.format format_of(private_key_contents)
        resource.type type_of(current_private_key)
      rescue
        # If there's an error reading, we assume format and type are wrong and don't futz with them
      end

      # Detect public key info
      if new_resource.public_key_path && ::File.exist?(new_resource.public_key_path)
        resource.public_key_path new_resource.public_key_path
        public_key_contents = ::File.read(new_resource.public_key_path)
        begin
          @current_public_key = OpenSSL::PKey.read(public_key_contents)
          @current_public_key_format = format_of(public_key_contents)
        rescue
          # If there's an error reading, we assume format will be wrong and don't futz with them
        end
      end

      @current_resource = resource
    else
      not_found_resource = Chef::Resource::PrivateKey.new(new_resource.path)
      not_found_resource.action :delete
      @current_resource = not_found_resource
    end
  end
end
