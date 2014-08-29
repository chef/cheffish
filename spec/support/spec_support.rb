require 'chef_zero/rspec'
require 'chef/server_api'
require 'cheffish'
require 'cheffish/basic_chef_client'
require 'chef/provider/chef_acl'
require 'uri'

module SpecSupport
  include ChefZero::RSpec

  def self.extended(klass)
    klass.class_eval do
      def rest
        Chef::ServerAPI.new
      end

      def get(path, *args)
        if path[0] == '/'
          path = URI.join(rest.url, path)
        end
        rest.get(path, *args)
      end

      def chef_run
        converge if !@converged
        event_sink.events
      end

      def event_sink
        @event_sink ||= EventSink.new
      end

      def basic_chef_client
        @basic_chef_client ||= begin
          Cheffish::BasicChefClient.new(nil, event_sink)
        end
      end

      def load_recipe(&block)
        basic_chef_client.load_block(&block)
      end

      def run_recipe(&block)
        load_recipe(&block)
        converge
      end

      def reset_chef_client
        @event_sink = nil
        @basic_chef_client = nil
        @converged = false
      end

      def converge
        if @converged
          raise "Already converged! Cannot converge twice, that's bad mojo."
        end
        @converged = true
        basic_chef_client.converge
      end
    end
  end

  def with_recipe(&block)
    before :each do
      load_recipe(&block)
    end

    after :each do
      if !@converged
        raise "Never tried to converge!"
      end
    end
  end

  def with_converge(&block)
    before :each do
      load_recipe(&block) if block_given?
      converge
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
    expect(actual_actions).to eq(expected_actions)
  end
  failure_message do |actual|
    updates = actual.select { |event, resource, action| event == :resource_updated }.to_a
    result = "expected that the chef_run would #{expected_actions.join(',')} #{resource_name}."
    if updates.size > 0
      result << " Actual updates were #{updates.map { |event, resource, action| "#{resource.to_s} => #{action.inspect}" }.join(', ')}"
    else
      result << " Nothing was updated."
    end
    result
  end
  failure_message_when_negated do |actual|
    updates = actual.select { |event, resource, action| event == :resource_updated }.to_a
    result = "expected that the chef_run would not #{expected_actions.join(',')} #{resource_name}."
    if updates.size > 0
      result << " Actual updates were #{updates.map { |event, resource, action| "#{resource.to_s} => #{action.inspect}" }.join(', ')}"
    else
      result << " Nothing was updated."
    end
    result
  end
end

RSpec::Matchers.define :update_acls do |acl_paths, expected_acls|

  errors = []

  match do |block|
    orig_json = {}
    Array(acl_paths).each do |acl_path|
      orig_json[acl_path] = get(acl_path)
    end

    block.call

    orig_json.each_pair do |acl_path, orig|
      changed = get(acl_path)
      expected_acls.each do |permission, hash|
        hash.each do |type, actors|
          actors.each do |actor|
            if actor[0] == '-'
              actor = actor[1..-1]
              errors << "#{acl_path} expected to remove #{type} #{actor} from #{permission} permissions" if changed[permission][type].include?(actor)
              orig[permission][type].delete(actor)
            else
              errors << "#{acl_path} expected to add #{type} #{actor} to #{permission} permissions" if !changed[permission][type].include?(actor)
              changed[permission][type].delete(actor)
            end
          end
        end
      end
      # After checking everything, see if the remaining acl is the same as before
      errors << "#{acl_path} updated more than expected!\nActual:\n#{changed}\nExpected:\n#{orig}" if changed != orig
    end
    errors.size == 0
  end

  failure_message do |block|
    errors.join("\n")
  end

  supports_block_expectations
end

RSpec.configure do |config|
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true

  config.before :each do
    Chef::Config.reset
  end
end

require 'chef/providers'
