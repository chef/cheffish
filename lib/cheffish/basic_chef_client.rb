require 'cheffish/version'
require 'chef/dsl/recipe'
require 'chef/event_dispatch/base'
require 'chef/event_dispatch/dispatcher'
require 'chef/node'
require 'chef/run_context'
require 'chef/runner'
require 'forwardable'

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

    def self.inline_resource(provider, provider_action, &block)
      events = ProviderEventForwarder.new(provider, provider_action)
      client = BasicChefClient.new(provider.node, events)
      client.load_block(&block)
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
