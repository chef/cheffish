require "openssl/cipher"
require "cheffish/base_resource"
require "openssl"
require "cheffish/key_formatter"

class Chef
  class Resource
    class PublicKey < Cheffish::BaseResource
      resource_name :public_key

      allowed_actions :create, :delete, :nothing
      default_action :create

      property :path, String, name_property: true
      property :format, [ :pem, :der, :openssh ], default: :openssh

      property :source_key
      property :source_key_path, String
      property :source_key_pass_phrase

      # We are not interested in Chef's cloning behavior here.
      def load_prior_resource(*args)
        Chef::Log.debug("Overloading #{resource_name}.load_prior_resource with NOOP")
      end

      action :create do
        if !new_source_key
          raise "No source key specified"
        end
        desired_output = encode_public_key(new_source_key)
        if Array(current_resource.action) == [ :delete ] || desired_output != IO.read(new_resource.path)
          converge_by "write #{new_resource.format} public key #{new_resource.path} from #{new_source_key_publicity} key #{new_resource.source_key_path}" do
            IO.write(new_resource.path, desired_output)
            # TODO permissions on file?
          end
        end
      end

      action :delete do
        if Array(current_resource.action) == [ :create ]
          converge_by "delete public key #{new_resource.path}" do
            ::File.unlink(new_resource.path)
          end
        end
      end

      action_class.class_eval do
        def encode_public_key(key)
          key_format = {}
          key_format[:format] = new_resource.format if new_resource.format
          Cheffish::KeyFormatter.encode(key, key_format)
        end

        attr_reader :current_public_key
        attr_reader :new_source_key_publicity

        def new_source_key
          @new_source_key ||= begin
            if new_resource.source_key.is_a?(String)
              source_key, source_key_format = Cheffish::KeyFormatter.decode(new_resource.source_key, new_resource.source_key_pass_phrase)
            elsif new_resource.source_key
              source_key = new_resource.source_key
            elsif new_resource.source_key_path
              source_key, source_key_format = Cheffish::KeyFormatter.decode(IO.read(new_resource.source_key_path), new_resource.source_key_pass_phrase, new_resource.source_key_path)
            else
              return nil
            end

            if source_key.private?
              @new_source_key_publicity = "private"
              source_key.public_key
            else
              @new_source_key_publicity = "public"
              source_key
            end
          end
        end

        def load_current_resource
          if ::File.exist?(new_resource.path)
            resource = Chef::Resource::PublicKey.new(new_resource.path, run_context)
            begin
              key, key_format = Cheffish::KeyFormatter.decode(IO.read(new_resource.path), nil, new_resource.path)
              if key
                @current_public_key = key
                resource.format key_format[:format]
              end
            rescue
              # If there is an error reading we assume format and such is broken
            end

            @current_resource = resource
          else
            not_found_resource = Chef::Resource::PublicKey.new(new_resource.path, run_context)
            not_found_resource.action :delete
            @current_resource = not_found_resource
          end
        end
      end

    end
  end
end
