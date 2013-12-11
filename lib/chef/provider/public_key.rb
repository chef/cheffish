require 'chef/provider/lwrp_base'
require 'openssl'
require 'cheffish/key_formatter'

class Chef::Provider::PublicKey < Chef::Provider::LWRPBase

  action :create do
    # TODO test this with source key that has a password
    source_key, source_key_format = Cheffish::KeyFormatter.decode(IO.read(new_resource.source_key_path), new_resource.source_key_pass_phrase, new_resource.source_key_path)
    if source_key.private?
      source_key_publicity = 'private'
      source_key = source_key.public_key
    else
      source_key_publicity = 'public'
    end

    desired_output = encode_public_key(source_key)
    if Array(current_resource.action) == [ :delete ] || desired_output != IO.read(new_resource.path)
      converge_by "write #{new_resource.format} public key #{new_resource.path} from #{source_key_publicity} key #{new_resource.source_key_path}" do
        IO.write(new_resource.path, desired_output)
        # TODO permissions on file?
      end
    end
  end

  action :delete do
    if Array(current_resource.action) == [ :create ]
      converge_by "delete public key #{new_resource.path}" do
        ::File.unlink(new_resource.path)
      end
    end
  end

  def whyrun_supported?
    true
  end

  protected

  def encode_public_key(key)
    key_format = {}
    key_format[:format] = new_resource.format if new_resource.format
    Cheffish::KeyFormatter.encode(key, key_format)
  end

  attr_reader :current_public_key

  def load_current_resource
    if ::File.exist?(new_resource.path)
      resource = Chef::Resource::PublicKey.new(new_resource.path)
      begin
        key, key_format = Cheffish::KeyFormatter.decode(IO.read(new_resource.path), nil, new_resource.path)
        if key
          @current_public_key = key
          resource.format key_format[:format]
        end
      rescue
        # If there is an error reading we assume format and such is broken
      end

      @current_resource = resource
    else
      not_found_resource = Chef::Resource::PublicKey.new(new_resource.path)
      not_found_resource.action :delete
      @current_resource = not_found_resource
    end
  end
end
