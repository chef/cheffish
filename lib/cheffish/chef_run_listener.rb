require 'chef/event_dispatch/base'

module Cheffish
  class ChefRunListener < Chef::EventDispatch::Base
    def initialize(node)
      @node = node
    end

    attr_reader :node

    def run_complete(_node)
      disconnect
    end

    def run_failed(_exception)
      disconnect
    end

    private

    def disconnect
      # Stop the servers
      if node.run_context
        node.run_context.cheffish.local_servers.each(&:stop)
      end
    end
  end
end
