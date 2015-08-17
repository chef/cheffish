require 'chef/provider/lwrp_base'
require 'chef_zero'

class Chef::Provider::ChefResolvedCookbooks < Chef::Provider::LWRPBase
  provides :chef_resolved_cookbooks

  action :resolve do
    new_resource.cookbooks_from.each do |path|
      ::Dir.entries(path).each do |name|
        if ::File.directory?(::File.join(path, name)) && name != '.' && name != '..'
          new_resource.berksfile.cookbook name, :path => ::File.join(path, name)
        end
      end
    end

    new_resource.berksfile.install

    # Ridley really really wants a key :/
    if new_resource.chef_server[:options][:signing_key_filename]
      new_resource.berksfile.upload(
        :server_url => new_resource.chef_server[:chef_server_url],
        :client_name => new_resource.chef_server[:options][:client_name],
        :client_key => new_resource.chef_server[:options][:signing_key_filename])
    else
      file = Tempfile.new('privatekey')
      begin
        file.write(ChefZero::PRIVATE_KEY)
        file.close

        new_resource.berksfile.upload(
          :server_url => new_resource.chef_server[:chef_server_url],
          :client_name => new_resource.chef_server[:options][:client_name] || 'me',
          :client_key => file.path)

      ensure
        file.close
        file.unlink
      end
    end
  end

end
