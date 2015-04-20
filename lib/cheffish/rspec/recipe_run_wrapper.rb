require 'cheffish/chef_run'

module Cheffish
  module RSpec
    class RecipeRunWrapper < ChefRun
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
