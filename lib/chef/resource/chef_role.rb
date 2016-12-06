require "cheffish"
require "cheffish/base_resource"
require "chef/run_list/run_list_item"
require "chef/chef_fs/data_handler/role_data_handler"

class Chef
  class Resource
    class ChefRole < Cheffish::BaseResource
      resource_name :chef_role

      property :role_name, Cheffish::NAME_REGEX, name_property: true
      property :description, String
      property :run_list, Array # We should let them specify it as a series of parameters too
      property :env_run_lists, Hash
      property :default_attributes, Hash
      property :override_attributes, Hash

      # default_attribute 'ip_address', '127.0.0.1'
      # default_attribute [ 'pushy', 'port' ], '9000'
      # default_attribute 'ip_addresses' do |existing_value|
      #   (existing_value || []) + [ '127.0.0.1' ]
      # end
      # default_attribute 'ip_address', :delete
      attr_reader :default_attribute_modifiers
      def default_attribute(attribute_path, value = NOT_PASSED, &block)
        @default_attribute_modifiers ||= []
        if value != NOT_PASSED
          @default_attribute_modifiers << [ attribute_path, value ]
        elsif block
          @default_attribute_modifiers << [ attribute_path, block ]
        else
          raise "default_attribute requires either a value or a block"
        end
      end

      # override_attribute 'ip_address', '127.0.0.1'
      # override_attribute [ 'pushy', 'port' ], '9000'
      # override_attribute 'ip_addresses' do |existing_value|
      #   (existing_value || []) + [ '127.0.0.1' ]
      # end
      # override_attribute 'ip_address', :delete
      attr_reader :override_attribute_modifiers
      def override_attribute(attribute_path, value = NOT_PASSED, &block)
        @override_attribute_modifiers ||= []
        if value != NOT_PASSED
          @override_attribute_modifiers << [ attribute_path, value ]
        elsif block
          @override_attribute_modifiers << [ attribute_path, block ]
        else
          raise "override_attribute requires either a value or a block"
        end
      end

      # Order matters--if two things here are in the wrong order, they will be flipped in the run list
      # recipe 'apache', 'mysql'
      # recipe 'recipe@version'
      # recipe 'recipe'
      # role ''
      attr_reader :run_list_modifiers
      attr_reader :run_list_removers
      def recipe(*recipes)
        if recipes.size == 0
          raise ArgumentError, "At least one recipe must be specified"
        end
        @run_list_modifiers ||= []
        @run_list_modifiers += recipes.map { |recipe| Chef::RunList::RunListItem.new("recipe[#{recipe}]") }
      end

      def role(*roles)
        if roles.size == 0
          raise ArgumentError, "At least one role must be specified"
        end
        @run_list_modifiers ||= []
        @run_list_modifiers += roles.map { |role| Chef::RunList::RunListItem.new("role[#{role}]") }
      end

      def remove_recipe(*recipes)
        if recipes.size == 0
          raise ArgumentError, "At least one recipe must be specified"
        end
        @run_list_removers ||= []
        @run_list_removers += recipes.map { |recipe| Chef::RunList::RunListItem.new("recipe[#{recipe}]") }
      end

      def remove_role(*roles)
        if roles.size == 0
          raise ArgumentError, "At least one role must be specified"
        end
        @run_list_removers ||= []
        @run_list_removers += roles.map { |recipe| Chef::RunList::RunListItem.new("role[#{role}]") }
      end

      action :create do
        differences = json_differences(current_json, new_json)

        if current_resource_exists?
          if differences.size > 0
            description = [ "update role #{new_resource.role_name} at #{rest.url}" ] + differences
            converge_by description do
              rest.put("roles/#{new_resource.role_name}", normalize_for_put(new_json))
            end
          end
        else
          description = [ "create role #{new_resource.role_name} at #{rest.url}" ] + differences
          converge_by description do
            rest.post("roles", normalize_for_post(new_json))
          end
        end
      end

      action :delete do
        if current_resource_exists?
          converge_by "delete role #{new_resource.role_name} at #{rest.url}" do
            rest.delete("roles/#{new_resource.role_name}")
          end
        end
      end

      action_class.class_eval do
        def load_current_resource
          begin
            @current_resource = json_to_resource(rest.get("roles/#{new_resource.role_name}"))
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
          json["run_list"] = apply_run_list_modifiers(new_resource.run_list_modifiers, new_resource.run_list_removers, json["run_list"])
          json["default_attributes"] = apply_modifiers(new_resource.default_attribute_modifiers, json["default_attributes"])
          json["override_attributes"] = apply_modifiers(new_resource.override_attribute_modifiers, json["override_attributes"])
          json
        end

        #
        # Helpers
        #

        def resource_class
          Chef::Resource::ChefRole
        end

        def data_handler
          Chef::ChefFS::DataHandler::RoleDataHandler.new
        end

        def keys
          {
            "name" => :role_name,
            "description" => :description,
            "run_list" => :run_list,
            "env_run_lists" => :env_run_lists,
            "default_attributes" => :default_attributes,
            "override_attributes" => :override_attributes,
          }
        end
      end
    end
  end
end
