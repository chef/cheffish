require "cheffish"
require "cheffish/base_resource"
require "chef/environment"
require "chef/chef_fs/data_handler/environment_data_handler"

class Chef
  class Resource
    class ChefEnvironment < Cheffish::BaseResource
      resource_name :chef_environment

      property :environment_name, Cheffish::NAME_REGEX, name_property: true
      property :description, String
      property :cookbook_versions, Hash, callbacks: {
        "should have valid cookbook versions" => lambda { |value| Chef::Environment.validate_cookbook_versions(value) },
      }
      property :default_attributes, Hash
      property :override_attributes, Hash

      # default 'ip_address', '127.0.0.1'
      # default [ 'pushy', 'port' ], '9000'
      # default 'ip_addresses' do |existing_value|
      #   (existing_value || []) + [ '127.0.0.1' ]
      # end
      # default 'ip_address', :delete
      attr_reader :default_attribute_modifiers
      def default(attribute_path, value = NOT_PASSED, &block)
        @default_attribute_modifiers ||= []
        if value != NOT_PASSED
          @default_attribute_modifiers << [ attribute_path, value ]
        elsif block
          @default_attribute_modifiers << [ attribute_path, block ]
        else
          raise "default requires either a value or a block"
        end
      end

      # override 'ip_address', '127.0.0.1'
      # override [ 'pushy', 'port' ], '9000'
      # override 'ip_addresses' do |existing_value|
      #   (existing_value || []) + [ '127.0.0.1' ]
      # end
      # override 'ip_address', :delete
      attr_reader :override_attribute_modifiers
      def override(attribute_path, value = NOT_PASSED, &block)
        @override_attribute_modifiers ||= []
        if value != NOT_PASSED
          @override_attribute_modifiers << [ attribute_path, value ]
        elsif block
          @override_attribute_modifiers << [ attribute_path, block ]
        else
          raise "override requires either a value or a block"
        end
      end

      alias :attributes :default_attributes
      alias :attribute :default

      action :create do
        differences = json_differences(current_json, new_json)

        if current_resource_exists?
          if differences.size > 0
            description = [ "update environment #{new_resource.environment_name} at #{rest.url}" ] + differences
            converge_by description do
              rest.put("environments/#{new_resource.environment_name}", normalize_for_put(new_json))
            end
          end
        else
          description = [ "create environment #{new_resource.environment_name} at #{rest.url}" ] + differences
          converge_by description do
            rest.post("environments", normalize_for_post(new_json))
          end
        end
      end

      action :delete do
        if current_resource_exists?
          converge_by "delete environment #{new_resource.environment_name} at #{rest.url}" do
            rest.delete("environments/#{new_resource.environment_name}")
          end
        end
      end

      action_class.class_eval do
        def load_current_resource
          begin
            @current_resource = json_to_resource(rest.get("environments/#{new_resource.environment_name}"))
          rescue Net::HTTPServerException => e
            if e.response.code == "404"
              @current_resource = not_found_resource
            else
              raise
            end
          end
        end

        def augment_new_json(json)
          # Apply modifiers
          json["default_attributes"] = apply_modifiers(new_resource.default_attribute_modifiers, json["default_attributes"])
          json["override_attributes"] = apply_modifiers(new_resource.override_attribute_modifiers, json["override_attributes"])
          json
        end

        #
        # Helpers
        #

        def resource_class
          Chef::Resource::ChefEnvironment
        end

        def data_handler
          Chef::ChefFS::DataHandler::EnvironmentDataHandler.new
        end

        def keys
          {
            "name" => :environment_name,
            "description" => :description,
            "cookbook_versions" => :cookbook_versions,
            "default_attributes" => :default_attributes,
            "override_attributes" => :override_attributes,
          }
        end
      end
    end
  end
end
