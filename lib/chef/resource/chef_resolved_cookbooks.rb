require 'chef_compat/resource'

class Chef
  class Resource
    class ChefResolvedCookbooks < ChefCompat::Resource
      use_automatic_resource_name

      allowed_actions :resolve, :nothing
      default_action :resolve

      def initialize(*args)
        super
        require 'berkshelf'
        berksfile Berkshelf::Berksfile.new('/tmp/Berksfile')
        chef_server run_context.cheffish.current_chef_server
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
      property :chef_server
    end
  end
end
