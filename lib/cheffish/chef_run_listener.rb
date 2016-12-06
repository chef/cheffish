require "chef/event_dispatch/base"

module Cheffish
  class ChefRunListener < Chef::EventDispatch::Base
    def initialize(node)
      @node = node
    end

    attr_reader :node

    def run_complete(node)
      disconnect
    end

    def run_failed(exception)
      disconnect
    end

    private

    def disconnect
      # Stop the servers
      if node.run_context
        node.run_context.cheffish.local_servers.each do |server|
          server.stop
        end
      end
    end
  end
end
