require 'cheffish'
require 'cheffish/chef_actor_resource_base'
require 'chef/resource/chef_user'
require 'chef/chef_fs/data_handler/user_data_handler'

class Chef
  class Resource
    class ChefUser < Cheffish::ChefActorResourceBase
      use_automatic_resource_name

      # Client attributes
      property :name, Cheffish::NAME_REGEX, name_property: true
      property :display_name, String
      property :admin, [true, false]
      property :email, String
      property :external_authentication_uid
      property :recovery_authentication_enabled, [true, false]
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

      # Action helpers
      action_class.class_eval do
        #
        # Helpers
        #
        # Gives us new_json, current_json, not_found_json, etc.

        def actor_type
          'user'
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
            'name' => :name,
            'username' => :name,
            'display_name' => :display_name,
            'admin' => :admin,
            'email' => :email,
            'password' => :password,
            'external_authentication_uid' => :external_authentication_uid,
            'recovery_authentication_enabled' => :recovery_authentication_enabled,
            'public_key' => :source_key
          }
        end
      end
    end
  end
end
