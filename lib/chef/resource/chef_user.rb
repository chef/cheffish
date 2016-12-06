require "cheffish"
require "cheffish/chef_actor_base"

class Chef
  class Resource
    class ChefUser < Cheffish::ChefActorBase
      resource_name :chef_user

      # Client attributes
      property :user_name, Cheffish::NAME_REGEX, name_property: true
      property :display_name, String
      property :admin, Boolean
      property :email, String
      property :external_authentication_uid
      property :recovery_authentication_enabled, Boolean
      property :password, String # Hmm.  There is no way to idempotentize this.
      #property :salt  # TODO server doesn't support sending or receiving these, but it's the only way to backup / restore a user
      #property :hashed_password
      #property :hash_type

      # Input key
      property :source_key # String or OpenSSL::PKey::*
      property :source_key_path, String
      property :source_key_pass_phrase

      # Output public key (if so desired)
      property :output_key_path, String
      property :output_key_format, [ :pem, :der, :openssh ], default: :openssh

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
        #
        # Helpers
        #
        # Gives us new_json, current_json, not_found_json, etc.

        def actor_type
          "user"
        end

        def actor_path
          "#{rest.root_url}/users"
        end

        def resource_class
          Chef::Resource::ChefUser
        end

        def data_handler
          Chef::ChefFS::DataHandler::UserDataHandler.new
        end

        def keys
          {
            "name" => :user_name,
            "username" => :user_name,
            "display_name" => :display_name,
            "admin" => :admin,
            "email" => :email,
            "password" => :password,
            "external_authentication_uid" => :external_authentication_uid,
            "recovery_authentication_enabled" => :recovery_authentication_enabled,
            "public_key" => :source_key,
          }
        end
      end
    end
  end
end
