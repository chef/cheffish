require 'cheffish/version'
require 'chef/dsl/recipe'
require 'chef/event_dispatch/base'
require 'chef/event_dispatch/dispatcher'
require 'chef/node'
require 'chef/run_context'
require 'chef/runner'
require 'forwardable'
require 'chef/providers'
require 'chef/resources'

module Cheffish
  class BasicChefClient
    include Chef::DSL::Recipe

    def initialize(node = nil, events = nil)
      if !node
        node = Chef::Node.new
        node.name 'basic_chef_client'
        node.automatic[:platform] = 'basic_chef_client'
        node.automatic[:platform_version] = Cheffish::VERSION
      end

      @event_catcher = BasicChefClientEvents.new
      dispatcher = Chef::EventDispatch::Dispatcher.new(@event_catcher)
      dispatcher.register(events) if events
      @run_context = Chef::RunContext.new(node, {}, dispatcher)
      @updated = []
      @cookbook_name = 'basic_chef_client'
    end

    extend Forwardable

    # Stuff recipes need
    attr_reader :run_context
    attr_accessor :cookbook_name
    attr_accessor :recipe_name
    def_delegators :@run_context, :resource_collection, :immediate_notifications, :delayed_notifications

    def add_resource(resource)
      resource.run_context = run_context
      run_context.resource_collection.insert(resource)
    end

    def load_block(&block)
      @recipe_name = 'block'
      instance_eval(&block)
    end

    def converge
      Chef::Runner.new(self).converge
    end

    def updates
      @event_catcher.updates
    end

    def updated?
      @event_catcher.updates.size > 0
    end

    # Builds a resource sans context, which can be later used in a new client's
    # add_resource() method.
    def self.build_resource(type, name, created_at=nil, &resource_attrs_block)
      created_at ||= caller[0]
      result = BasicChefClient.new.build_resource(type, name, created_at, &resource_attrs_block)
      result
    end

    def self.inline_resource(provider, provider_action, *resources, &block)
      events = ProviderEventForwarder.new(provider, provider_action)
      client = BasicChefClient.new(provider.node, events)
      resources.each do |resource|
        client.add_resource(resource)
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
