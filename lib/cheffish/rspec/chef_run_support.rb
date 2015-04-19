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

      def with_converge(&recipe)
        before :each do
          r = recipe(&recipe)
          r.converge
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
          r = recipe(&recipe)
          r.converge
          expect(r)
        end

        def expect_converge(&recipe)
          r = recipe(&recipe)
          expect { r.converge }
        end

        def recipe(&recipe)
          RecipeRunWrapper.new(chef_config, &recipe)
        end

        def converge(&recipe)
          r = RecipeRunWrapper.new(chef_config, &recipe)
          r.converge
          r
        end

        def chef_client
          @chef_client ||= ChefRunWrapper.new(chef_config)
        end
      end
    end
  end
end
