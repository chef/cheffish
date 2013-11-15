# We have to do this because "actor_provider_base.rb" is loaded before "chef_provider_base.rb" :(
module Cheffish
  class ChefProviderBase < Chef::Provider::LWRPBase
  end
end

class Cheffish::ActorProviderBase < Cheffish::ChefProviderBase

  def create_actor(regenerate)
    if new_resource.before
      new_resource.before.call(new_resource)
      if new_resource.action == [ :regenerate_keys ]
        regenerate = true
      end
    end

    if new_resource.private_key && regenerate
      raise "Cannot regenerate key when private_key is specified"
    end

    # As key owner, we will do what we must to ensure our keys match the server,
    # including blowing away keys on one or the other.
    if new_resource.key_owner
      # If we *need* a private key but don't have one, we have to regenerate one, 
      if new_resource.private_key_path && !new_private_key
        regenerate = true
      end
    end

    # Create or update the client/user

    differences = json_differences(current_json, new_json)

    if current_resource_exists?
      # Update the actor if it's different
      if differences.size > 0 || regenerate
        if regenerate
          new_json['private_key'] = true
          new_json.delete('public_key')
          description = [ "update and regenerate keys for #{actor_type} #{new_resource.name} at #{rest.url}" ]
        else
          description = [ "update #{actor_type} #{new_resource.name} at #{rest.url}" ]
        end
        description += differences
        converge_by description do
          result = rest.put("#{actor_type}s/#{new_resource.name}", normalize_for_put(new_json))
          if result['private_key']
            @server_private_key = OpenSSL::PKey.read(result['private_key'])
            @server_public_key = server_private_key.public_key
          elsif result['public_key']
            @server_public_key = OpenSSL::PKey.read(result['public_key'])
          end
        end
      end
    else
      # Create the actor if it's missing
      description = [ "create #{actor_type} #{new_resource.name} at #{rest.url}" ] + differences
      converge_by description do
        result = rest.post("#{actor_type}s", normalize_for_post(new_json))
        if result['private_key']
          @server_private_key = read_key(result['private_key'])
          @server_public_key = server_private_key.public_key
        elsif result['public_key']
          @server_public_key = read_key(result['public_key'])
        end
      end
    end

    # Write out the private key

    @server_private_key = new_private_key if !server_private_key
    if server_public_key
      if server_private_key && server_private_key.public_key.to_s != server_public_key.to_s
        raise "Desired private key does not match #{actor_type} #{new_resource.name} on #{rest.url}.  Set key_owner to true or send action :regenerate_key to fix."
      end
    else
      @server_public_key = new_private_key.public_key if !server_public_key
    end

    if new_resource.private_key_path
      if server_private_key
        # Create or update the private key
        if !current_resource.private_key_path
          action = 'create'
        elsif !current_private_key || current_private_key.to_s != server_private_key.to_s
          action = 'overwrite'
        else 
          action = nil
        end

        if action
          converge_by "#{action} private key #{new_resource.private_key_path}" do
            ::File.open(new_resource.private_key_path, 'w') do |file|
              file.write(server_private_key.to_pem)
            end
          end
        end
      end
    end

    # Write out the public key

    if new_resource.public_key_path
      if server_public_key
        if !current_resource.public_key_path
          action = 'create'
        elsif !current_public_key || server_public_key.to_s != current_public_key.to_s
          action = 'overwrite'
        else
          action = nil
        end

        if action
          converge_by "#{action} public key #{new_resource.public_key_path}" do
            ::File.open(new_resource.public_key_path, 'w') do |file|
              file.write(server_public_key.to_pem)
            end
          end
        end
      end
    end

    if new_resource.after
      new_resource.after.call(self, new_json, server_private_key, server_public_key)
    end
  end

  def delete_actor
    if current_resource_exists?
      converge_by "delete #{actor_type} #{new_resource.name} at #{rest.url}" do
        rest.delete("#{actor_type}s/#{new_resource.name}")
        Chef::Log.info("#{new_resource} deleted #{actor_type} #{new_resource.name} at #{rest.url}")
      end
    end
    if current_resource.public_key_path
      converge_by "delete public key #{current_resource.public_key_path}" do
        ::File.unlink(current_resource.public_key_path)
      end
    end
    if current_resource.private_key_path
      converge_by "delete private key #{current_resource.private_key_path}" do
        ::File.unlink(current_resource.private_key_path)
      end
    end
  end

  def current_private_key
    if current_resource.private_key_path
      @current_private_key ||= read_key(::File.read(current_resource.private_key_path))
    else
      nil
    end
  end

  def current_public_key
    if current_resource.public_key_path
      @current_public_key ||= read_key(::File.read(current_resource.public_key_path))
    else
      nil
    end
  end

  def new_private_key
    if new_resource.private_key
      read_key(new_resource.private_key)
    else
      current_private_key
    end
  end

  def augment_new_json(json)
    # As key owner, we will do what we must to ensure our keys match the server,
    # including blowing away keys on one or the other.
    if new_resource.key_owner
      # If we have a private key on hand, we'll send the public for that to the server.
      if new_private_key
        @server_public_key = new_private_key.public_key
        json['public_key'] = server_public_key.to_pem
      # If we *need* a private key but don't have one, we have to regenerate one, 
      elsif new_resource.private_key_path
        regenerate = true
      end
    end
    json
  end

  def augment_current_json(json)
    # As key owner, we will do what we must to ensure our keys match the server,
    # including blowing away keys on one or the other.
    if new_resource.key_owner
      # If we have a private key on hand, we'll send the public for that to the server.
      if new_private_key
        json['public_key'] = new_private_key.public_key.to_pem
      end
    end
    json
  end

  def read_key(str)
    OpenSSL::PKey.read(str)
  rescue
    nil
  end

  attr_reader :server_private_key
  attr_reader :server_public_key

  def load_current_resource
    begin
      json = rest.get("#{actor_type}s/#{new_resource.name}")
      if json['public_key']
        @server_public_key = read_key(json['public_key'])
      end
      @current_resource = json_to_resource(json)
    rescue Net::HTTPServerException => e
      if e.response.code == "404"
        @current_resource = not_found_resource
      else
        raise
      end
    end

    if new_resource.public_key_path && ::File.exist?(new_resource.public_key_path)
      current_resource.public_key_path new_resource.public_key_path
    end
    if new_resource.private_key_path && ::File.exist?(new_resource.private_key_path)
      current_resource.private_key_path new_resource.private_key_path
    end
  end

end