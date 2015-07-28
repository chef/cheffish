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
          example = recipe.binding.eval('self')
          @client.load_block(&recipe)
          @client.define_singleton_method(:method_missing) do |name, *args, &block|
            example.public_send(name, *args, &block)
          end
        end
        @client
      end
    end
  end
end
