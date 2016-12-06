require "cheffish/base_resource"
require "chef_zero"

class Chef
  class Resource
    class ChefResolvedCookbooks < Cheffish::BaseResource
      resource_name :chef_resolved_cookbooks

      def initialize(*args)
        super
        require "berkshelf"
        berksfile Berkshelf::Berksfile.new("/tmp/Berksfile")
        @cookbooks_from = []
      end

      extend Forwardable

      def_delegators :@berksfile, :cookbook, :extension, :group, :metadata, :source

      def cookbooks_from(path = nil)
        if path
          @cookbooks_from << path
        else
          @cookbooks_from
        end
      end

      property :berksfile

      action :resolve do
        new_resource.cookbooks_from.each do |path|
          ::Dir.entries(path).each do |name|
            if ::File.directory?(::File.join(path, name)) && name != "." && name != ".."
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
          file = Tempfile.new("privatekey")
          begin
            file.write(ChefZero::PRIVATE_KEY)
            file.close

            new_resource.berksfile.upload(
              :server_url => new_resource.chef_server[:chef_server_url],
              :client_name => new_resource.chef_server[:options][:client_name] || "me",
              :client_key => file.path)

          ensure
            file.close
            file.unlink
          end
        end
      end
    end
  end
end
