require "cheffish/key_formatter"
require "cheffish/base_resource"

module Cheffish
  class ChefActorBase < Cheffish::BaseResource

    action_class.class_eval do
      def create_actor
        if new_resource.before
          new_resource.before.call(new_resource)
        end

        # Create or update the client/user
        current_public_key = new_json["public_key"]
        differences = json_differences(current_json, new_json)
        if current_resource_exists?
          # Update the actor if it's different
          if differences.size > 0
            description = [ "update #{actor_type} #{new_resource.name} at #{actor_path}" ] + differences
            converge_by description do
              result = rest.put("#{actor_path}/#{new_resource.name}", normalize_for_put(new_json))
              current_public_key, current_public_key_format = Cheffish::KeyFormatter.decode(result["public_key"]) if result["public_key"]
            end
          end
        else
          # Create the actor if it's missing
          if !new_public_key
            raise "You must specify a public key to create a #{actor_type}!  Use the private_key resource to create a key, and pass it in with source_key_path."
          end
          description = [ "create #{actor_type} #{new_resource.name} at #{actor_path}" ] + differences
          converge_by description do
            result = rest.post("#{actor_path}", normalize_for_post(new_json))
            current_public_key, current_public_key_format = Cheffish::KeyFormatter.decode(result["public_key"]) if result["public_key"]
          end
        end

        # Write out the public key
        if new_resource.output_key_path
          # TODO use inline_resource
          key_content = Cheffish::KeyFormatter.encode(current_public_key, { :format => new_resource.output_key_format })
          if !current_resource.output_key_path
            action = "create"
          elsif key_content != IO.read(current_resource.output_key_path)
            action = "overwrite"
          else
            action = nil
          end
          if action
            converge_by "#{action} public key #{new_resource.output_key_path}" do
              IO.write(new_resource.output_key_path, key_content)
            end
          end
          # TODO permissions?
        end

        if new_resource.after
          new_resource.after.call(self, new_json, server_private_key, server_public_key)
        end
      end

      def delete_actor
        if current_resource_exists?
          converge_by "delete #{actor_type} #{new_resource.name} at #{actor_path}" do
            rest.delete("#{actor_path}/#{new_resource.name}")
            Chef::Log.info("#{new_resource} deleted #{actor_type} #{new_resource.name} at #{rest.url}")
          end
        end
        if current_resource.output_key_path
          converge_by "delete public key #{current_resource.output_key_path}" do
            ::File.unlink(current_resource.output_key_path)
          end
        end
      end

      def new_public_key
        @new_public_key ||= begin
          if new_resource.source_key
            if new_resource.source_key.is_a?(String)
              key, key_format = Cheffish::KeyFormatter.decode(new_resource.source_key)

              if key.private?
                key.public_key
              else
                key
              end
            elsif new_resource.source_key.private?
              new_resource.source_key.public_key
            else
              new_resource.source_key
            end
          elsif new_resource.source_key_path
            source_key_path = new_resource.source_key_path
            if Pathname.new(source_key_path).relative?
              source_key_str, source_key_path = Cheffish.get_private_key_with_path(source_key_path, run_context.config)
            else
              source_key_str = IO.read(source_key_path)
            end
            source_key, source_key_format = Cheffish::KeyFormatter.decode(source_key_str, new_resource.source_key_pass_phrase, source_key_path)
            if source_key.private?
              source_key.public_key
            else
              source_key
            end
          else
            nil
          end
        end
      end

      def augment_new_json(json)
        if new_public_key
          json["public_key"] = new_public_key.to_pem
        end
        json
      end

      def load_current_resource
        begin
          json = rest.get("#{actor_path}/#{new_resource.name}")
          @current_resource = json_to_resource(json)
        rescue Net::HTTPServerException => e
          if e.response.code == "404"
            @current_resource = not_found_resource
          else
            raise
          end
        end

        if new_resource.output_key_path && ::File.exist?(new_resource.output_key_path)
          current_resource.output_key_path = new_resource.output_key_path
        end
      end
    end
  end
end
