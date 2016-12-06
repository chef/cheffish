require "cheffish/base_properties"

module Cheffish
  module NodeProperties
    include Cheffish::BaseProperties

    # Grab environment from with_environment
    def initialize(*args)
      super
      chef_environment run_context.cheffish.current_environment
    end

    property :node_properties_name, Cheffish::NAME_REGEX, name_property: true
    property :chef_environment, Cheffish::NAME_REGEX
    property :run_list, Array # We should let them specify it as a series of parameters too
    property :attributes, Hash

    # attribute 'ip_address', '127.0.0.1'
    # attribute [ 'pushy', 'port' ], '9000'
    # attribute 'ip_addresses' do |existing_value|
    #   (existing_value || []) + [ '127.0.0.1' ]
    # end
    # attribute 'ip_address', :delete
    attr_accessor :attribute_modifiers
    def attribute(attribute_path, value = Chef::NOT_PASSED, &block)
      @attribute_modifiers ||= []
      if value != Chef::NOT_PASSED
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
      attribute "tags" do |existing_tags|
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
      attribute "tags" do |existing_tags|
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
        attribute("tags")
      else
        tags = tags[0] if tags.size == 1 && tags[0].kind_of?(Array)
        attribute "tags", tags.map { |tag| tag.to_s }
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
      @run_list_removers += roles.map { |role| Chef::RunList::RunListItem.new("role[#{role}]") }
    end
  end
end
