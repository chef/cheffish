require 'chef_zero/rspec'
require 'chef/server_api'
require 'cheffish/rspec/repository_support'
require 'uri'
require 'cheffish/basic_chef_client'
require 'cheffish/rspec/chef_run_wrapper'
require 'cheffish/rspec/recipe_run_wrapper'

module Cheffish
  module RSpec
    module ChefRunSupport
      include ChefZero::RSpec
      include RepositorySupport

      def self.extended(klass)
        klass.class_eval do
          include ChefRunSupportInstanceMethods
        end
      end

      def when_the_chef_12_server(*args, **options, &block)
        if Gem::Version.new(ChefZero::VERSION) >= Gem::Version.new('3.1')
          when_the_chef_server(*args, :osc_compat => false, :single_org => false, **options, &block)
        end
      end

      def with_recipe(&block)
        before :each do
          load_recipe(&block)
        end

        after :each do
          if !chef_client.converge_failed? && !chef_client.converged?
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

      module ChefRunSupportInstanceMethods
        def rest
          ::Chef::ServerAPI.new
        end

        def get(path, *args)
          if path[0] == '/'
            path = URI.join(rest.url, path)
          end
          rest.get(path, *args)
        end

        def chef_config
          {}
        end

        def expect_recipe(&recipe)
          expect(recipe(&recipe))
        end

        def recipe(&recipe)
          RecipeRunWrapper.new(chef_config, &recipe)
        end

        def chef_client
          @chef_client ||= ChefRunWrapper.new(chef_config)
        end

        def chef_run
          converge if !chef_client.converged?
          event_sink.events
        end

        def event_sink
          chef_client.event_sink
        end

        def basic_chef_client
          chef_client.client
        end

        def load_recipe(&recipe)
          chef_client.client.load_block(&recipe)
        end

        def run_recipe(&recipe)
          load_recipe(&recipe)
          converge
        end

        def reset_chef_client
          @event_sink = nil
          @basic_chef_client = nil
        end

        def converge
          if chef_client.converged?
            raise "Already converged! Cannot converge twice, that's bad mojo."
          end
          chef_client.converge
        end
      end
    end
  end
end
