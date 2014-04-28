require 'chef/run_list/run_list_item'
require 'cheffish/inline_resource'

module Cheffish
  NAME_REGEX = /^[.\-[:alnum:]_]+$/

  def self.inline_resource(provider, &block)
    InlineResource.new(provider).instance_eval(&block)
  end

  NOT_PASSED=Object.new

  def self.node_attributes(klass)
    klass.class_eval do
      attribute :name, :kind_of => String, :regex => Cheffish::NAME_REGEX, :name_attribute => true
      attribute :chef_environment, :kind_of => String, :regex => Cheffish::NAME_REGEX
      attribute :run_list, :kind_of => Array # We should let them specify it as a series of parameters too
      attribute :attributes, :kind_of => Hash

      # Specifies that this is a complete specification for the environment (i.e. attributes you don't specify will be
      # reset to their defaults)
      attribute :complete, :kind_of => [TrueClass, FalseClass]

      attribute :raw_json, :kind_of => Hash
      attribute :chef_server, :kind_of => Hash

      # attribute 'ip_address', '127.0.0.1'
      # attribute [ 'pushy', 'port' ], '9000'
      # attribute 'ip_addresses' do |existing_value|
      #   (existing_value || []) + [ '127.0.0.1' ]
      # end
      # attribute 'ip_address', :delete
      attr_accessor :attribute_modifiers
      def attribute(attribute_path, value=NOT_PASSED, &block)
        @attribute_modifiers ||= []
        if value != NOT_PASSED
          @attribute_modifiers << [ attribute_path, value ]
        elsif block
          @attribute_modifiers << [ attribute_path, block ]
        else
          raise "attribute requires either a value or a block"
        end
      end

      # Patchy tags
      # tag 'webserver', 'apache', 'myenvironment'
      def tag(*tags)
        attribute 'tags' do |existing_tags|
          existing_tags ||= []
          tags.each do |tag|
            if !existing_tags.include?(tag.to_s)
              existing_tags << tag.to_s
            end
          end
          existing_tags
        end
      end
      def remove_tag(*tags)
        attribute 'tags' do |existing_tags|
          if existing_tags
            tags.each do |tag|
              existing_tags.delete(tag.to_s)
            end
          end
          existing_tags
        end
      end

      # NON-patchy tags
      # tags :a, :b, :c # removes all other tags
      def tags(*tags)
        if tags.size == 0
          attribute('tags')
        else
          tags = tags[0] if tags.size == 1 && tags[0].kind_of?(Array)
          attribute 'tags', tags.map { |tag| tag.to_s }
        end
      end

      # Order matters--if two things here are in the wrong order, they will be flipped in the run list
      # recipe 'apache', 'mysql'
      # recipe 'recipe@version'
      # recipe 'recipe'
      # role ''
      attr_accessor :run_list_modifiers
      attr_accessor :run_list_removers
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
    end
  end
end

# Include all recipe objects so require 'cheffish' brings in the whole recipe DSL

require 'cheffish/recipe_dsl'
require 'chef/resource/chef_client'
require 'chef/resource/chef_data_bag'
require 'chef/resource/chef_data_bag_item'
require 'chef/resource/chef_environment'
require 'chef/resource/chef_node'
require 'chef/resource/chef_role'
require 'chef/resource/chef_user'
require 'chef/resource/private_key'
require 'chef/resource/public_key'
require 'chef/provider/chef_client'
require 'chef/provider/chef_data_bag'
require 'chef/provider/chef_data_bag_item'
require 'chef/provider/chef_environment'
require 'chef/provider/chef_node'
require 'chef/provider/chef_role'
require 'chef/provider/chef_user'
require 'chef/provider/private_key'
require 'chef/provider/public_key'
