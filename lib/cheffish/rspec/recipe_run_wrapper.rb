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
            if example.respond_to?(name)
              example.public_send(name, *args, &block)
            else
              super(name, *args, &block)
            end
          end
          # This is called by respond_to?, and is required to make sure the
          # resource knows that we will in fact call the given method.
          @client.define_singleton_method(:respond_to_missing?) do |name, include_private = false|
            example.respond_to?(name)
          end
          # Respond true to is_a?(Chef::Provider) so that Chef::Recipe::DSL.build_resource
          # will hook resources up to the example let variables as well (via
          # enclosing_provider).
          # Please don't hurt me
          @client.define_singleton_method(:is_a?) do |klass|
            klass == Chef::Provider || super
          end

          @client.load_block(&recipe)
        end
        @client
      end
    end
  end
end
