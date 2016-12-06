require "cheffish/version"
require "chef/dsl/recipe"
require "chef/event_dispatch/base"
require "chef/event_dispatch/dispatcher"
require "chef/node"
require "chef/run_context"
require "chef/runner"
require "forwardable"
require "chef/providers"
require "chef/resources"

module Cheffish
  class BasicChefClient
    include Chef::DSL::Recipe

    def initialize(node = nil, events = nil, **chef_config)
      if !node
        node = Chef::Node.new
        node.name "basic_chef_client"
        node.automatic[:platform] = "basic_chef_client"
        node.automatic[:platform_version] = Cheffish::VERSION
      end

      # Decide on the config we want for this chef client
      @chef_config = chef_config

      with_chef_config do
        @cookbook_name = "basic_chef_client"
        @event_catcher = BasicChefClientEvents.new
        dispatcher = Chef::EventDispatch::Dispatcher.new(@event_catcher)
        case events
        when nil
        when Array
          events.each { |e| dispatcher.register(e) } if events
        else
          dispatcher.register(events)
        end
        @run_context = Chef::RunContext.new(node, {}, dispatcher)
        @updated = []
        @cookbook_name = "basic_chef_client"
      end
    end

    extend Forwardable

    # Stuff recipes need
    attr_reader :chef_config
    attr_reader :run_context
    attr_accessor :cookbook_name
    attr_accessor :recipe_name

    def add_resource(resource)
      with_chef_config do
        resource.run_context = run_context
        run_context.resource_collection.insert(resource)
      end
    end

    def load_block(&block)
      with_chef_config do
        @recipe_name = "block"
        instance_eval(&block)
      end
    end

    def converge
      with_chef_config do
        Chef::Runner.new(run_context).converge
      end
    end

    def updates
      @event_catcher.updates
    end

    def updated?
      @event_catcher.updates.size > 0
    end

    # Builds a resource sans context, which can be later used in a new client's
    # add_resource() method.
    def self.build_resource(type, name, created_at = nil, &resource_attrs_block)
      created_at ||= caller[0]
      result = BasicChefClient.new.tap do |client|
        client.with_chef_config do
          client.build_resource(type, name, created_at, &resource_attrs_block)
        end
      end
      result
    end

    def self.inline_resource(provider, provider_action, *resources, &block)
      events = ProviderEventForwarder.new(provider, provider_action)
      client = BasicChefClient.new(provider.node, events)
      client.with_chef_config do
        resources.each do |resource|
          client.add_resource(resource)
        end
      end
      client.load_block(&block) if block
      client.converge
      client.updated?
    end

    def self.converge_block(node = nil, events = nil, &block)
      client = BasicChefClient.new(node, events)
      client.load_block(&block)
      client.converge
      client.updated?
    end

    def with_chef_config(&block)
      old_chef_config = Chef::Config.save
      if chef_config[:log_location]
        old_loggers = Chef::Log.loggers
        Chef::Log.init(chef_config[:log_location])
      end
      if chef_config[:log_level]
        old_level = Chef::Log.level
        Chef::Log.level(chef_config[:log_level])
      end
      # if chef_config[:stdout]
      #   old_stdout = $stdout
      #   $stdout = chef_config[:stdout]
      # end
      # if chef_config[:stderr]
      #   old_stderr = $stderr
      #   $stderr = chef_config[:stderr]
      # end
      begin
        deep_merge_config(chef_config, Chef::Config)
        yield
      ensure
        # $stdout = old_stdout if chef_config[:stdout]
        # $stderr = old_stderr if chef_config[:stderr]
        if old_loggers
          Chef::Log.logger = old_loggers.shift
          old_loggers.each { |l| Chef::Log.loggers.push(l) }
        elsif chef_config[:log_level]
          Chef::Log.level = old_level
        end
        Chef::Config.restore(old_chef_config)
      end
    end

    def deep_merge_config(src, dest)
      src.each do |name, value|
        if value.is_a?(Hash) && dest[name].is_a?(Hash)
          deep_merge_config(value, dest[name])
        else
          dest[name] = value
        end
      end
    end

    class BasicChefClientEvents < Chef::EventDispatch::Base
      def initialize
        @updates = []
      end

      attr_reader :updates

      # Called after a resource has been completely converged.
      def resource_updated(resource, action)
        updates << [ resource, action ]
      end
    end

    class ProviderEventForwarder < Chef::EventDispatch::Base
      def initialize(provider, provider_action)
        @provider = provider
        @provider_action = provider_action
      end

      attr_reader :provider
      attr_reader :provider_action

      def resource_update_applied(resource, action, update)
        provider.run_context.events.resource_update_applied(provider.new_resource, provider_action, update)
      end
    end
  end
end
