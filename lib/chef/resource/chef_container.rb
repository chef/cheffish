require 'cheffish'
require 'chef_compat/resource'

class Chef
  class Resource
    class ChefContainer < ChefCompat::Resource
      resource_name :chef_container

      allowed_actions :create, :delete, :nothing
      default_action :create

      # Grab environment from with_environment
      def initialize(*args)
        super
        chef_server run_context.cheffish.current_chef_server
      end

      property :name, :kind_of => String, :regex => Cheffish::NAME_REGEX, :name_attribute => true
      property :chef_server, :kind_of => Hash
    end
  end
end
