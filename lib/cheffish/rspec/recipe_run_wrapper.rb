require "cheffish/chef_run"
require "forwardable"

module Cheffish
  module RSpec
    class RecipeRunWrapper < ChefRun
      def initialize(chef_config, example: nil, &recipe)
        super(chef_config)
        @recipe = recipe
        @example = example || recipe.binding.eval("self")
      end

      attr_reader :recipe
      attr_reader :example

      def client
        if !@client
          super
          example = self.example

          #
          # Support for both resources and rspec example's let variables:
          #
          # In 12.4, the elimination of a bunch of metaprogramming in 12.4
          # changed how Chef DSL is defined in code: resource methods are now
          # explicitly defined in `Chef::DSL::Recipe`. In 12.3, no actual
          # methods were defined and `respond_to?(:file)` would return false.
          # If we reach `method_missing` here, it means that we either have a
          # 12.3-ish resource or we want to call a `let` variable.
          #
          @client.instance_eval { @rspec_example = example }
          def @client.method_missing(name, *args, &block) # rubocop:disable Lint/NestedMethodDefinition
            # If there is a let variable, call it. This is because in 12.4,
            # the parent class is going to call respond_to?(name) to find out
            # if someone was doing weird things, and then call send(). This
            # would result in an infinite loop, coming right. Back. Here.
            # A fix to chef is incoming, but we still need this if we want to
            # work with Chef 12.4.
            if Gem::Version.new(Chef::VERSION) >= Gem::Version.new("12.4")
              if @rspec_example.respond_to?(name)
                return @rspec_example.public_send(name, *args, &block)
              end
            end

            # In 12.3 or below, method_missing was the only way to call
            # resources. If we are in 12.4, we still need to call the crazy
            # method_missing metaprogramming because backcompat.
            begin
              super
            rescue NameError
              if @rspec_example.respond_to?(name)
                @rspec_example.public_send(name, *args, &block)
              else
                raise
              end
            end
          end

          # This is called by respond_to?, and is required to make sure the
          # resource knows that we will in fact call the given method.
          def @client.respond_to_missing?(name, include_private = false) # rubocop:disable Lint/NestedMethodDefinition
            @rspec_example.respond_to?(name, include_private) || super
          end

          # Respond true to is_a?(Chef::Provider) so that Chef::Recipe::DSL.build_resource
          # will hook resources up to the example let variables as well (via
          # enclosing_provider).
          # Please don't hurt me
          def @client.is_a?(klass) # rubocop:disable Lint/NestedMethodDefinition
            klass == Chef::Provider || super(klass)
          end

          @client.load_block(&recipe)
        end
        @client
      end
    end
  end
end
