require 'chef/provider/lwrp_base'
require 'openssl'
require 'cheffish/key_formatter'

class Chef::Provider::PrivateKey < Chef::Provider::LWRPBase

  action :create do
    create_key(false)
  end

  action :regenerate do
    create_key(true)
  end

  action :delete do
    if Array(current_resource.action) == [ :create ]
      converge_by "delete private key #{new_resource.path}" do
        ::File.unlink(new_resource.path)
      end
    end
  end

  use_inline_resources

  def whyrun_supported?
    true
  end

  def create_key(regenerate)
    if new_source_key
      #
      # Create private key from source
      #
      desired_output = encode_private_key(new_source_key)
      if Array(current_resource.action) == [ :delete ] || desired_output != IO.read(new_resource.path)
        converge_by "reformat key at #{new_resource.source_key_path} to #{new_resource.format} private key #{new_resource.path} (#{new_resource.pass_phrase ? ", #{new_resource.cipher} password" : ""})" do
          IO.write(new_resource.path, desired_output)
        end
      end

    else
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

          write_private_key(new_private_key)
        end
      else
        # Warn if existing key has different characteristics than expected
        if current_resource.size != new_resource.size
          Chef::Log.warn("Mismatched key size!  #{current_resource.path} is #{current_resource.size} bytes, desired is #{new_resource.size} bytes.  Use action :regenerate to force key regeneration.")
        elsif current_resource.type != new_resource.type
          Chef::Log.warn("Mismatched key type!  #{current_resource.path} is #{current_resource.type}, desired is #{new_resource.type} bytes.  Use action :regenerate to force key regeneration.")
        end

        if current_resource.format != new_resource.format
          converge_by "change format of #{new_resource.type} private key #{new_resource.path} from #{current_resource.format} to #{new_resource.format}" do
            write_private_key(current_private_key)
          end
        end
      end
    end

    if new_resource.public_key_path && (new_private_key || current_private_key)
      public_key_path = new_resource.public_key_path
      public_key_format = new_resource.public_key_format
      local_current_private_key = current_private_key
      Cheffish.inline_resource(self) do
        public_key public_key_path do
          source_key (new_private_key || local_current_private_key)
          format public_key_format
        end
      end
    end
  end

  def encode_private_key(key)
    key_format = {}
    key_format[:format] = new_resource.format if new_resource.format
    key_format[:pass_phrase] = new_resource.pass_phrase if new_resource.pass_phrase
    key_format[:cipher] = new_resource.cipher if new_resource.cipher
    Cheffish::KeyFormatter.encode(key, key_format)
  end

  def write_private_key(key)
    IO.write(new_resource.path, encode_private_key(key))
    # TODO permissions on file?
  end

  def new_source_key
    @new_source_key ||= begin
      if new_resource.source_key.is_a?(String)
        source_key, source_key_format = Cheffish::KeyFormatter.decode(new_resource.source_key, new_resource.source_key_pass_phrase)
        source_key
      elsif new_resource.source_key
        new_resource.source_key
      elsif new_resource.source_key_path
        source_key, source_key_format = Cheffish::KeyFormatter.decode(IO.read(new_resource.source_key_path), new_resource.source_key_pass_phrase, new_resource.source_key_path)
        source_key
      else
        nil
      end
    end
  end

  attr_reader :current_private_key

  def load_current_resource
    if ::File.exist?(new_resource.path)
      resource = Chef::Resource::PrivateKey.new(new_resource.path)

      begin
        key, key_format = Cheffish::KeyFormatter.decode(IO.read(new_resource.path), new_resource.pass_phrase, new_resource.path)
        if key
          @current_private_key = key
          resource.format key_format[:format]
          resource.type key_format[:type]
          resource.size key_format[:size]
          resource.exponent key_format[:exponent]
          resource.pass_phrase key_format[:pass_phrase]
          resource.cipher key_format[:cipher]
        end
      rescue
        # If there's an error reading, we assume format and type are wrong and don't futz with them
      end
  
      @current_resource = resource
    else
      not_found_resource = Chef::Resource::PrivateKey.new(new_resource.path)
      not_found_resource.action :delete
      @current_resource = not_found_resource
    end
  end
end
