require_relative "../../cheffish"
require_relative "../../cheffish/chef_actor_base"

class Chef
  class Resource
    class ChefClient < Cheffish::ChefActorBase
      provides :chef_client, target_mode: true

      # Client attributes
      property :chef_client_name, Cheffish::NAME_REGEX, name_property: true
      property :admin, [TrueClass, FalseClass]
      property :validator, [TrueClass, FalseClass]

      # Input key
      property :source_key # String or OpenSSL::PKey::*
      property :source_key_path, String
      property :source_key_pass_phrase

      # Output public key (if so desired)
      property :output_key_path, String
      property :output_key_format, Symbol, default: :openssh, equal_to: %i{pem der openssh}

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

      action_class do
        def actor_type
          "client"
        end

        def actor_path
          "clients"
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
            "name" => :chef_client_name,
            "admin" => :admin,
            "validator" => :validator,
            "public_key" => :source_key,
          }
        end
      end
    end
  end
end
