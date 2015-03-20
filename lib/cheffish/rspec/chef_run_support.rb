require 'chef_zero/rspec'
require 'chef/server_api'
require 'cheffish/rspec/repository_support'
require 'uri'
require 'cheffish/basic_chef_client'

module Cheffish
  module RSpec
    module ChefRunSupport
      include ChefZero::RSpec

      def when_the_chef_12_server(*args, **options, &block)
        if Gem::Version.new(ChefZero::VERSION) >= Gem::Version.new('3.1')
          when_the_chef_server(*args, :osc_compat => false, :single_org => false, **options, &block)
        end
      end

      def self.extended(klass)
        klass.class_eval do
          extend RepositorySupport

          def rest
            ::Chef::ServerAPI.new
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
              ::Cheffish::BasicChefClient.new(nil, event_sink)
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
  end
end
