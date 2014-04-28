require 'chef_zero/rspec'
require 'chef/recipe'
require 'chef/run_context'
require 'chef/event_dispatch/dispatcher'
require 'chef/cookbook/cookbook_collection'
require 'chef/runner'
require 'chef/server_api'
require 'cheffish'

module SpecSupport
  include ChefZero::RSpec

  def self.extended(klass)
    klass.class_eval do
      def get(*args)
        Chef::ServerAPI.new.get(*args)
      end

      def chef_run
        @event_sink.events
      end

      def run_context
        @run_context ||= begin
          node = Chef::Node.new
          node.name 'test'
          node.automatic[:platform] = 'test'
          node.automatic[:platform_version] = 'test'
          Chef::RunContext.new(node, {}, Chef::EventDispatch::Dispatcher.new(event_sink))
        end
      end

      def event_sink
        @event_sink ||= EventSink.new
      end

      def run_recipe(&block)
        recipe = Chef::Recipe.new('test', 'test', run_context)
        recipe.instance_eval(&block)
        Chef::Runner.new(run_context).converge
      end
    end
  end

  def with_recipe(&block)
    before :each do
      run_recipe(&block)
    end
  end

  class EventSink
    def initialize
      @events = []
    end

    attr_reader :events

    def method_missing(method, *args)
      @events << [ method, *args ]
    end
  end
end

RSpec::Matchers.define :have_updated do |resource_name, *expected_actions|
  match do |actual|
    actual_actions = actual.select { |event, resource, action| event == :resource_updated && resource.to_s == resource_name }.map { |event, resource, action| action }
    actual_actions.should == expected_actions
  end
  failure_message_for_should do |actual|
    updates = actual.select { |event, resource, action| event == :resource_updated }.to_a
    result = "expected that the chef_run would #{expected_actions.join(',')} #{resource_name}."
    if updates.size > 0
      result << " Actual updates were #{updates.map { |event, resource, action| "#{resource.to_s} => #{action.inspect}" }.join(', ')}"
    else
      result << " Nothing was updated."
    end
    result
  end
end

RSpec.configure do |config|
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
  config.treat_symbols_as_metadata_keys_with_true_values = true

  config.before :each do
    Chef::Config.reset
  end
end

require 'chef/providers'
