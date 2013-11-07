class Chef::Provider::CheffishClient < Cheffish::ChefProviderBase

  def whyrun_supported?
    true
  end

  action :create do
    create_client(false)
  end

  action :regenerate_keys do
    create_client(true)
  end

  action :delete do
    if current_resource_exists?
      converge_by "delete client #{new_resource.name} at #{rest.url}" do
        rest.delete("clients/#{new_resource.name}")
        Chef::Log.info("#{new_resource} deleted client #{new_resource.name} at #{rest.url}")
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

  def create_client(regenerate)
    current_private_key = nil
    if current_resource.private_key_path
      current_private_key = read_key(::File.read(current_resource.private_key_path))
    end
    current_public_key = nil
    if current_resource.public_key_path
      current_public_key = read_key(::File.read(current_resource.public_key_path))
    end
    new_json = self.new_json.dup
    current_json = self.current_json.dup

    # As key owner, we will do what we must to ensure our keys match the server,
    # including blowing away keys on one or the other.
    if new_resource.key_owner
      # If we have a private key on hand, we'll send the public for that to the server.
      if current_private_key
        new_json['public_key'] = current_private_key.public_key.to_pem
        current_json['public_key'] = server_public_key.to_pem if server_public_key
        @server_public_key = new_json['public_key']
      # If we *need* a private key but don't have one, we have to regenerate one, 
      elsif new_resource.private_key_path
        regenerate = true
      end
    end

    differences = json_differences(current_json, new_json)

    if current_resource_exists?
      # Update the client if it's different
      if differences.size > 0 || regenerate
        if regenerate
          new_json['private_key'] = true
          new_json.delete('public_key')
          different_fields.delete('public_key')
          description = [ "update and regenerate keys for client #{new_resource.name} at #{rest.url}" ]
        else
          description = [ "update client #{new_resource.name} at #{rest.url}" ]
        end
        description += differences
        converge_by description do
          result = rest.put("clients/#{new_resource.name}", normalize_for_put(new_json))
          if result['private_key']
            @server_private_key = OpenSSL::PKey.read(result['private_key'])
            @server_public_key = server_private_key.public_key
          elsif result['public_key']
            @server_public_key = OpenSSL::PKey.read(result['public_key'])
          end
        end
      end
    else
      # Create the client if it's missing
      description = [ "create client #{new_resource.name} at #{rest.url}" ] + differences
      converge_by description do
        result = rest.post("clients", normalize_for_post(new_json))
        if result['private_key']
          @server_private_key = read_key(result['private_key'])
          @server_public_key = server_private_key.public_key
        elsif result['public_key']
          @server_public_key = read_key(result['public_key'])
        end
      end
    end

    # Write out the private key
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
      elsif server_public_key
        if current_private_key.public_key.to_s != server_public_key.to_s
          raise "Private key #{current_resource.private_key_path} does not match client #{new_resource.name} on #{rest.url}.  Set key_owner to true or send action :regenerate_key to fix."
        end
      end
    end

    # Write out the public key
    if new_resource.public_key_path
      if server_public_key
        new_public_key = server_public_key
      elsif current_private_key
        new_public_key = current_private_key.public_key
      else
        new_public_key = nil
      end

      if new_public_key
        if !current_resource.public_key_path
          action = 'create'
        elsif !current_public_key || new_public_key.to_s != current_public_key.to_s
          action = 'overwrite'
        else
          action = nil
        end

        if action
          converge_by "#{action} public key #{new_resource.public_key_path}" do
            ::File.open(new_resource.public_key_path, 'w') do |file|
              file.write(new_public_key.to_pem)
            end
          end
        end
      end
    end
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
      json = rest.get("clients/#{new_resource.name}")
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


  #
  # Helpers
  #
  # Gives us new_json, current_json, not_found_json, etc.
  require 'chef/chef_fs/data_handler/client_data_handler'

  def resource_class
    Chef::Resource::CheffishClient
  end

  def data_handler
    Chef::ChefFS::DataHandler::ClientDataHandler.new
  end

  def keys
    {
      'name' => :name,
      'admin' => :admin,
      'validator' => :validator
    }
  end

end