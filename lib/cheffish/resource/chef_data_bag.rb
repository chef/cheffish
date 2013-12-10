require 'cheffish'
require 'chef/resource/lwrp_base'
require 'cheffish/provider/chef_data_bag'

module Cheffish
  module Resource
    class ChefDataBag < Chef::Resource::LWRPBase
      self.resource_name = 'chef_data_bag'
      provides :chef_data_bag
      def provider
        Cheffish::Provider::ChefDataBag
      end

      actions :create, :delete, :nothing
      default_action :create

      def initialize(*args)
        super
        chef_server Cheffish.enclosing_chef_server
      end

      attribute :name, :kind_of => String, :regex => Cheffish::NAME_REGEX, :name_attribute => true

      attribute :chef_server, :kind_of => Hash
    end
  end
end
