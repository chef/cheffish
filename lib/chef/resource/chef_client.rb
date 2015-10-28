require 'cheffish'
require 'cheffish/chef_actor_base'

class Chef
  class Resource
    class ChefClient < Cheffish::ChefActorBase
      resource_name :chef_client

      # Client attributes
      property :name, :kind_of => String, :regex => Cheffish::NAME_REGEX, :name_attribute => true
      property :admin, :kind_of => [TrueClass, FalseClass]
      property :validator, :kind_of => [TrueClass, FalseClass]

      # Input key
      property :source_key # String or OpenSSL::PKey::*
      property :source_key_path, :kind_of => String
      property :source_key_pass_phrase

      # Output public key (if so desired)
      property :output_key_path, :kind_of => String
      property :output_key_format, :kind_of => Symbol, :default => :openssh, :equal_to => [ :pem, :der, :openssh ]

      # If this is set, client is not patchy
      property :complete, :kind_of => [TrueClass, FalseClass]

      property :raw_json, :kind_of => Hash

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
