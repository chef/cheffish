module Cheffish
  class DummyBootstrapper
    def machine_context(recipe_context, name)
      DummyMachineContext.new(recipe_context, name)
    end

    class DummyMachineContext
      def initialize(recipe_context, name)
        @recipe_context = recipe_context
        @name = name
      end

      attr_reader :recipe_context
      attr_reader :name
      attr_reader :node_json

      # Gets desired node json (may not be on the server yet), and adds any attributes the machine context
      # wants to have.  Caller is responsible for subsequently saving the node json.
      def filter_node(node_json)
        @node_json = node_json
      end

      # Read a file from the machine.  Returns nil if the machine is down or inaccessible.
      def read_file(path)
        nil
      end

      # Name of the resource which handles converging
      def converge_resource_name
        "file[/Users/jkeiser/x.txt]"
      end

      # Create the raw machine, power it up such that it can be connected to.  Should be done in resources added to recipe_context.
      # When this resource succeeds, a connection can be made to the machine so that read_file and chef_client_setup
      # can be run against it.
      #
      # Attributes include standard resource attributes, plus:
      # before PROC - calls proc with (resource) just before resource executes
      def raw_machine(&block)
      end

      # Set up chef client.  Should be done in resources added to recipe_context.
      #
      # Attributes include standard resource attributes, plus:
      # client_name "NAME" - name of Chef client this chef-client will use for authentication
      # client_key "KEY" - private key of the Chef client
      # before PROC - calls proc with (resource) just before resource executes
      def chef_client_setup(&block)
      end

      # Converge the machine.  Should be done in resources added to recipe_context.
      #
      # Attributes include standard resource attributes, plus:
      # before PROC - calls proc with (resource) just before resource executes
      def converge(&block)
        resource = recipe_context.instance_eval do
          file '/Users/jkeiser/x.txt' do
            content 'hi'
          end
        end
        resource.instance_eval(&block) if block
        resource
      end

      # Get a file onto the machine.  Should be done in resources added to recipe_context.
      #
      # Attributes include standard resource attributes, plus:
      # content "TEXT" - content to put in file
      # source "/path/to/source/file.txt" - file to read source data from
      # before PROC - calls proc with (resource) just before resource executes
      def file(remote_path, &block)
      end

      # Get a file onto the machine.  Should be done in resources added to recipe_context.
      #
      # Attributes include standard resource attributes, plus:
      # before PROC - calls proc with (resource) just before resource executes
      def disconnect
      end
    end
  end
end