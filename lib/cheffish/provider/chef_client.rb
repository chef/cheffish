require 'cheffish/actor_provider_base'
require 'cheffish/resource/chef_client'
require 'chef/chef_fs/data_handler/client_data_handler'

module Cheffish
  module Provider
    class ChefClient < Cheffish::ActorProviderBase

      def whyrun_supported?
        true
      end

      def actor_type
        'client'
      end

      action :create do
        create_actor
      end

      action :delete do
        delete_actor
      end

      #
      # Helpers
      #

      def resource_class
        Cheffish::Resource::ChefClient
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
  end
end