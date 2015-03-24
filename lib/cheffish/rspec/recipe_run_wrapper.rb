require 'cheffish/rspec/chef_run_wrapper'

module Cheffish
  module RSpec
    class RecipeRunWrapper < ChefRunWrapper
      def initialize(chef_config, &recipe)
        super(chef_config)
        @recipe = recipe
      end

      attr_reader :recipe

      def client
        if !@client
          super
          @client.load_block(&recipe)
        end
        @client
      end
    end
  end
end
