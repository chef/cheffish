require 'cheffish/chef_run'

module Cheffish
  module RSpec
    class RecipeRunWrapper < ChefRun
      def initialize(chef_config, example: nil, &recipe)
        super(chef_config)
        @recipe = recipe
        @example = example || recipe.binding.eval('self')
      end

      attr_reader :recipe
      attr_reader :example

      def client
        if !@client
          super
          example = self.example
          # Call into the rspec example's let variables and other methods
          @client.define_singleton_method(:method_missing) do |name, *args, &block|
            example.public_send(name, *args, &block)
          end
          @client.load_block(&recipe)
        end
        @client
      end
    end
  end
end
