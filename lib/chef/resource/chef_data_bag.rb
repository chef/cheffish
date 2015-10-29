require 'cheffish'
require 'chef_compat/resource'

class Chef
  class Resource
    class ChefDataBag < ChefCompat::Resource
      resource_name :chef_data_bag

      allowed_actions :create, :delete, :nothing
      default_action :create

      def initialize(*args)
        super
        chef_server run_context.cheffish.current_chef_server
      end

      property :name, :kind_of => String, :regex => Cheffish::NAME_REGEX, :name_attribute => true

      property :chef_server, :kind_of => Hash
    end
  end
end
