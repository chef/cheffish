require "cheffish"
require "chef/config"
require "cheffish/base_resource"
require "chef/chef_fs/data_handler/data_bag_item_data_handler"
require "chef/encrypted_data_bag_item"

class Chef
  class Resource
    class ChefDataBagItem < Cheffish::BaseResource
      resource_name :chef_data_bag_item

      def initialize(*args)
        super
        if !property_is_set?(:data_bag) && run_context.cheffish.current_data_bag
          data_bag run_context.cheffish.current_data_bag
        end
        encryption = run_context.cheffish.current_data_bag_item_encryption
        if encryption
          encrypt true if encryption[:encrypt_all]
          secret encryption[:secret] if encryption[:secret]
          secret_path encryption[:secret_path] || run_context.config[:encrypted_data_bag_secret] if encryption[:secret_path] || run_context.config[:encrypted_data_bag_secret]
          encryption_cipher encryption[:encryption_cipher] if encryption[:encryption_cipher]
          encryption_version encryption[:encryption_version] || run_context.config[:data_bag_encrypt_version] if encryption[:encryption_version] || run_context.config[:data_bag_encrypt_version]
          old_secret encryption[:old_secret] if encryption[:old_secret]
          old_secret_path encryption[:old_secret_path] if encryption[:old_secret_path]
        end
      end

      # If data_bag and id are not specified, take them from name.
      # name can either be id, or data_bag/id
      property :id, String, default: lazy { name.split("/", 2)[-1] }
      property :data_bag, String, default: lazy {
        split = name.split("/", 2)
        split.size >= 2 ? split[0] : nil
      }

      property :raw_data, Hash

      # If secret or secret_path are set, encrypt is assumed true.  encrypt exists mainly for with_secret and with_secret_path
      property :encrypt, Boolean, default: lazy {
        if secret.nil? && secret_path.nil?
          false
        else
          true
        end
      }
      property :secret, String
      property :secret_path, String
      property :encryption_version, Integer

      # Old secret (or secrets) to read the old data bag when we are changing keys and re-encrypting data
      property :old_secret, [String, Array]
      property :old_secret_path, [String, Array]

      # value 'ip_address', '127.0.0.1'
      # value [ 'pushy', 'port' ], '9000'
      # value 'ip_addresses' do |existing_value|
      #   (existing_value || []) + [ '127.0.0.1' ]
      # end
      # value 'ip_address', :delete
      attr_reader :raw_data_modifiers
      def value(raw_data_path, value = NOT_PASSED, &block)
        @raw_data_modifiers ||= []
        if value != NOT_PASSED
          @raw_data_modifiers << [ raw_data_path, value ]
        elsif block
          @raw_data_modifiers << [ raw_data_path, block ]
        else
          raise "value requires either a value or a block"
        end
      end

      action :create do
        differences = calculate_differences

        if current_resource_exists?
          if differences.size > 0
            description = [ "update data bag item #{new_resource.id} at #{rest.url}" ] + differences
            converge_by description do
              rest.put("data/#{new_resource.data_bag}/#{new_resource.id}", normalize_for_put(new_json))
            end
          end
        else
          description = [ "create data bag item #{new_resource.id} at #{rest.url}" ] + differences
          converge_by description do
            rest.post("data/#{new_resource.data_bag}", normalize_for_post(new_json))
          end
        end
      end

      action :delete do
        if current_resource_exists?
          converge_by "delete data bag item #{new_resource.id} at #{rest.url}" do
            rest.delete("data/#{new_resource.data_bag}/#{new_resource.id}")
          end
        end
      end

      action_class.class_eval do
        def load_current_resource
          begin
            json = rest.get("data/#{new_resource.data_bag}/#{new_resource.id}")
            resource = Chef::Resource::ChefDataBagItem.new(new_resource.name, run_context)
            resource.raw_data json
            @current_resource = resource
          rescue Net::HTTPServerException => e
            if e.response.code == "404"
              @current_resource = not_found_resource
            else
              raise
            end
          end

          # Determine if data bag is encrypted and if so, what its version is
          first_real_key, first_real_value = (current_resource.raw_data || {}).select { |key, value| key != "id" && !value.nil? }.first
          if first_real_value
            if first_real_value.is_a?(Hash) &&
                first_real_value["version"].is_a?(Integer) &&
                first_real_value["version"] > 0 &&
                first_real_value.has_key?("encrypted_data")

              current_resource.encrypt true
              current_resource.encryption_version first_real_value["version"]

              decrypt_error = nil

              # Check if the desired secret is the one (which it generally should be)

              if new_resource.secret || new_resource.secret_path
                begin
                  Chef::EncryptedDataBagItem::Decryptor.for(first_real_value, new_secret).for_decrypted_item
                  current_resource.secret new_secret
                rescue Chef::EncryptedDataBagItem::DecryptionFailure
                  decrypt_error = $!
                end
              end

              # If the current secret doesn't work, look through the specified old secrets

              if !current_resource.secret
                old_secrets = []
                if new_resource.old_secret
                  old_secrets += Array(new_resource.old_secret)
                end
                if new_resource.old_secret_path
                  old_secrets += Array(new_resource.old_secret_path).map do |secret_path|
                    Chef::EncryptedDataBagItem.load_secret(new_resource.old_secret_file)
                  end
                end
                old_secrets.each do |secret|
                  begin
                    Chef::EncryptedDataBagItem::Decryptor.for(first_real_value, secret).for_decrypted_item
                    current_resource.secret secret
                  rescue Chef::EncryptedDataBagItem::DecryptionFailure
                    decrypt_error = $!
                  end
                end

                # If we couldn't figure out the secret, emit a warning (this isn't a fatal flaw unless we
                # need to reuse one of the values from the data bag)
                if !current_resource.secret
                  if decrypt_error
                    Chef::Log.warn "Existing data bag is encrypted, but could not decrypt: #{decrypt_error.message}."
                  else
                    Chef::Log.warn "Existing data bag is encrypted, but no secret was specified."
                  end
                end
              end
            end
          else

            # There are no encryptable values, so pretend encryption is the same as desired

            current_resource.encrypt(new_resource.encrypt) unless new_resource.encrypt.nil?
            current_resource.encryption_version(new_resource.encryption_version) if new_resource.encryption_version
            if new_resource.secret || new_resource.secret_path
              current_resource.secret new_secret
            end
          end
        end

        def new_json
          @new_json ||= begin
            if new_encrypt
              # Encrypt new stuff
              result = encrypt(new_decrypted, new_secret, new_resource.encryption_version)
            else
              result = new_decrypted
            end
            result
          end
        end

        def new_encrypt
          new_resource.encrypt.nil? ? current_resource.encrypt : new_resource.encrypt
        end

        def new_secret
          @new_secret ||= begin
            if new_resource.secret
              new_resource.secret
            elsif new_resource.secret_path
              Chef::EncryptedDataBagItem.load_secret(new_resource.secret_path)
            elsif new_resource.encrypt.nil?
              current_resource.secret
            else
              raise "Data bag item #{new_resource.name} has encryption on but no secret or secret_path is specified"
            end
          end
        end

        def decrypt(json, secret)
          Chef::EncryptedDataBagItem.new(json, secret).to_hash
        end

        def encrypt(json, secret, version)
          old_version = run_context.config[:data_bag_encrypt_version]
          run_context.config[:data_bag_encrypt_version] = version
          begin
            Chef::EncryptedDataBagItem.encrypt_data_bag_item(json, secret)
          ensure
            run_context.config[:data_bag_encrypt_version] = old_version
          end
        end

        # Get the desired (new) json pre-encryption, for comparison purposes
        def new_decrypted
          @new_decrypted ||= begin
            if new_resource.complete
              result = new_resource.raw_data || {}
            else
              result = current_decrypted.merge(new_resource.raw_data || {})
            end
            result["id"] = new_resource.id
            result = apply_modifiers(new_resource.raw_data_modifiers, result)
          end
        end

        # Get the current json decrypted, for comparison purposes
        def current_decrypted
          @current_decrypted ||= begin
            if current_resource.secret
              decrypt(current_resource.raw_data || { "id" => new_resource.id }, current_resource.secret)
            elsif current_resource.encrypt
              raise "Could not decrypt current data bag item #{current_resource.name}"
            else
              current_resource.raw_data || { "id" => new_resource.id }
            end
          end
        end

        # Figure out the differences between new and current
        def calculate_differences
          if new_encrypt
            if current_resource.encrypt
              # Both are encrypted, check if the encryption type is the same
              description = ""
              if new_secret != current_resource.secret
                description << " with new secret"
              end
              if new_resource.encryption_version != current_resource.encryption_version
                description << " from v#{current_resource.encryption_version} to v#{new_resource.encryption_version} encryption"
              end

              if description != ""
                # Encryption is different, we're reencrypting
                differences = [ "re-encrypt#{description}"]
              else
                # Encryption is the same, we're just updating
                differences = []
              end
            else
              # New stuff should be encrypted, old is not.  Encrypting.
              differences = [ "encrypt with v#{new_resource.encryption_version} encryption" ]
            end

            # Get differences in the actual json
            if current_resource.secret
              json_differences(current_decrypted, new_decrypted, false, "", differences)
            elsif current_resource.encrypt
              # Encryption is different and we can't read the old values.  Only allow the change
              # if we're overwriting the data bag item
              if !new_resource.complete
                raise "Cannot encrypt #{new_resource.name} due to failure to decrypt existing resource.  Set 'complete true' to overwrite or add the old secret as old_secret / old_secret_path."
              end
              differences = [ "overwrite data bag item (cannot decrypt old data bag item)"]
              differences = (new_resource.raw_data.keys & current_resource.raw_data.keys).map { |key| "overwrite #{key}" }
              differences += (new_resource.raw_data.keys - current_resource.raw_data.keys).map { |key| "add #{key}" }
              differences += (current_resource.raw_data.keys - new_resource.raw_data.keys).map { |key| "remove #{key}" }
            else
              json_differences(current_decrypted, new_decrypted, false, "", differences)
            end
          else
            if current_resource.encrypt
              # New stuff should not be encrypted, old is.  Decrypting.
              differences = [ "decrypt data bag item to plaintext" ]
            else
              differences = []
            end
            json_differences(current_decrypted, new_decrypted, true, "", differences)
          end
          differences
        end

        #
        # Helpers
        #

        def resource_class
          Chef::Resource::ChefDataBagItem
        end

        def data_handler
          Chef::ChefFS::DataHandler::DataBagItemDataHandler.new
        end

        def keys
          {
            "id" => :id,
            "data_bag" => :data_bag,
            "raw_data" => :raw_data,
          }
        end

        def not_found_resource
          resource = super
          resource.data_bag new_resource.data_bag
          resource
        end

        def fake_entry
          FakeEntry.new("#{new_resource.id}.json", FakeEntry.new(new_resource.data_bag))
        end
      end
    end
  end
end
