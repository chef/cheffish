require 'chef/provider/lwrp_base'
require 'openssl'
require 'cheffish/key_formatter'

class Chef::Provider::PrivateKey < Chef::Provider::LWRPBase
  provides :private_key

  action :create do
    create_key(false, :create)
  end

  action :regenerate do
    create_key(true, :regenerate)
  end

  action :delete do
    if current_resource.path
      converge_by "delete private key #{new_path}" do
        ::File.unlink(new_path)
      end
    end
  end

  use_inline_resources

  def whyrun_supported?
    true
  end

  def create_key(regenerate, action)
    if @should_create_directory
      Cheffish.inline_resource(self, action) do
        directory run_context.config[:private_key_write_path]
      end
    end

    final_private_key = nil
    if new_source_key
      #
      # Create private key from source
      #
      desired_output = encode_private_key(new_source_key)
      if current_resource.path == :none || desired_output != IO.read(new_path)
        converge_by "reformat key at #{new_resource.source_key_path} to #{new_resource.format} private key #{new_path} (#{new_resource.pass_phrase ? ", #{new_resource.cipher} password" : ""})" do
          IO.write(new_path, desired_output)
        end
      end

      final_private_key = new_source_key

    else
      #
      # Generate a new key
      #
      if current_resource.action == [ :delete ] || regenerate ||
        (new_resource.regenerate_if_different &&
          (!current_private_key ||
           current_resource.size != new_resource.size ||
           current_resource.type != new_resource.type))

       case new_resource.type
        when :rsa
          if new_resource.exponent
            final_private_key = OpenSSL::PKey::RSA.generate(new_resource.size, new_resource.exponent)
          else
            final_private_key = OpenSSL::PKey::RSA.generate(new_resource.size)
          end
        when :dsa
          final_private_key = OpenSSL::PKey::DSA.generate(new_resource.size)
        end

        generated_key = true
      elsif !current_private_key
        raise "Could not read private key from #{current_resource.path}: missing pass phrase?"
      else
        final_private_key = current_private_key
        generated_key = false
      end

      if generated_key
        generated_description = " (#{new_resource.size} bits#{new_resource.pass_phrase ? ", #{new_resource.cipher} password" : ""})"

        if new_path != :none
          action = current_resource.path == :none ? 'create' : 'overwrite'
          converge_by "#{action} #{new_resource.type} private key #{new_path}#{generated_description}" do
            write_private_key(final_private_key)
          end
        else
          converge_by "generate private key#{generated_description}" do
          end
        end
      else
        # Warn if existing key has different characteristics than expected
        if current_resource.size != new_resource.size
          Chef::Log.warn("Mismatched key size!  #{current_resource.path} is #{current_resource.size} bytes, desired is #{new_resource.size} bytes.  Use action :regenerate to force key regeneration.")
        elsif current_resource.type != new_resource.type
          Chef::Log.warn("Mismatched key type!  #{current_resource.path} is #{current_resource.type}, desired is #{new_resource.type} bytes.  Use action :regenerate to force key regeneration.")
        end

        if current_resource.format != new_resource.format
          converge_by "change format of #{new_resource.type} private key #{new_path} from #{current_resource.format} to #{new_resource.format}" do
            write_private_key(current_private_key)
          end
        elsif (@current_file_mode & 0077) != 0
          new_mode = @current_file_mode & 07700
          converge_by "change mode of private key #{new_path} to #{new_mode.to_s(8)}" do
            ::File.chmod(new_mode, new_path)
          end
        end
      end
    end

    if new_resource.public_key_path
      public_key_path = new_resource.public_key_path
      public_key_format = new_resource.public_key_format
      Cheffish.inline_resource(self, action) do
        public_key public_key_path do
          source_key final_private_key
          format public_key_format
        end
      end
    end

    if new_resource.after
      new_resource.after.call(new_resource, final_private_key)
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
    ::File.open(new_path, 'w') do |file|
      file.chmod(0600)
      file.write(encode_private_key(key))
    end
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

  def new_path
    new_key_with_path[1]
  end

  def new_key_with_path
    path = new_resource.path
    if path.is_a?(Symbol)
      return [ nil, path ]
    elsif Pathname.new(path).relative?
      private_key, private_key_path = Cheffish.get_private_key_with_path(path, run_context.config)
      if private_key
        return [ private_key, (private_key_path || :none) ]
      elsif run_context.config[:private_key_write_path]
        @should_create_directory = true
        path = ::File.join(run_context.config[:private_key_write_path], path)
        return [ nil, path ]
      else
        raise "Could not find key #{path} and Chef::Config.private_key_write_path is not set."
      end
    elsif ::File.exist?(path)
      return [ IO.read(path), path ]
    else
      return [ nil, path ]
    end
  end

  def load_current_resource
    resource = Chef::Resource::PrivateKey.new(new_resource.name, run_context)

    new_key, new_path = new_key_with_path
    if new_path != :none && ::File.exist?(new_path)
      resource.path new_path
      @current_file_mode = ::File.stat(new_path).mode
    else
      resource.path :none
    end

    if new_key
      begin
        key, key_format = Cheffish::KeyFormatter.decode(new_key, new_resource.pass_phrase, new_path)
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
        Chef::Log.warn("Error reading #{new_path}: #{$!}")
      end
    else
      resource.action :delete
    end

    @current_resource = resource
  end
end
