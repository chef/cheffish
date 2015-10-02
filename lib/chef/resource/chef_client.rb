require 'cheffish/chef_actor_resource_base'
require 'chef/resource/chef_client'
require 'chef/chef_fs/data_handler/client_data_handler'

class Chef
  class Resource
    class ChefClient < Cheffish::ChefActorResourceBase
      use_automatic_resource_name

      # Client attributes
      property :name, Cheffish::NAME_REGEX, name_property: true
      property :admin, [true, false]
      property :validator, [true, false]

      # Input key
      property :source_key # String or OpenSSL::PKey::*
      property :source_key_path, String
      property :source_key_pass_phrase

      # Output public key (if so desired)
      property :output_key_path, String
      property :output_key_format, [ :pem, :der, :openssh ], default: :openssh

      # If this is set, client is not patchy
      property :complete, [true, false]

      property :raw_json, Hash

      # Proc that runs just before the resource executes.  Called with (resource)
      def before(&block)
        block ? @before = block : @before
      end

      # Proc that runs after the resource completes.  Called with (resource, json, private_key, public_key)
      def after(&block)
        block ? @after = block : @after
      end

      action :create do
        create_actor
      end

      action :delete do
        delete_actor
      end

      # Helpers for action
      action_class.class_eval do
        def actor_type
          'client'
        end

        def actor_path
          'clients'
        end

        #
        # Helpers
        #

        def resource_class
          Chef::Resource::ChefClient
        end

        def data_handler
          Chef::ChefFS::DataHandler::ClientDataHandler.new
        end

        def keys
          {
            'name' => :name,
            'admin' => :admin,
            'validator' => :validator,
            'public_key' => :source_key
          }
        end
      end
    end
  end
end
