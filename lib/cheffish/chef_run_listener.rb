require 'chef/event_dispatch/base'

module Cheffish
  class ChefRunListener < Chef::EventDispatch::Base
    def initialize(run_context)
      @run_context = run_context
    end

    def run_complete(node)
      disconnect
    end

    def run_failed(exception)
      disconnect
    end

    private

    def disconnect
      # Stop the servers
      run_context.cheffish.local_servers.each do |server|
        server.stop
      end
    end
  end
end
