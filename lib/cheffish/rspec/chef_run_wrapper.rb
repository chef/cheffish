require 'cheffish/basic_chef_client'

module Cheffish
  module RSpec
    class ChefRunWrapper
      def initialize(chef_config)
        @chef_config = chef_config
      end

      attr_reader :chef_config

      def client
        @client ||= begin
          @stdout = StringIO.new
          @stderr = StringIO.new
          @logs   = StringIO.new
          @client = ::Cheffish::BasicChefClient.new(nil,
            [ event_sink, Chef::Formatters.new(:doc, stdout, stderr) ],
            {
              stdout:          stdout,
              stderr:          stderr,
              log_location:    logs,
              log_level:       :debug,
              verbose_logging: false
            }.merge(chef_config)
          )
        end
      end

      def event_sink
        @event_sink ||= EventSink.new
      end

      #
      # output
      #
      attr_reader :stdout
      attr_reader :stderr
      attr_reader :logs

      def resources
        client.resource_collection
      end

      def converge
        client.converge
      end

      def reset
        @client = nil
        @converged = nil
        @stdout = nil
        @stderr = nil
        @logs = nil
      end

      def converged?
        @converged
      end

      def updated?
        client.updated?
      end

      def up_to_date?
        !client.updated?
      end

      def output_for_failure_message
        message = ""
        if stdout && !stdout.string.empty?
          message << "---                    ---\n"
          message << "--- Chef Client Output ---\n"
          message << "---                    ---\n"
          message << stdout.string
        end
        if stderr && !stderr.string.empty?
          message << "---                          ---\n"
          message << "--- Chef Client Error Output ---\n"
          message << "---                          ---\n"
          message << stderr.string
        end
        if logs && !logs.string.empty?
          message << "---                  ---\n"
          message << "--- Chef Client Logs ---\n"
          message << "---                  ---\n"
          message << logs.string
        end
        message
      end

      class EventSink
        def initialize
          @events = []
        end

        attr_reader :events

        def method_missing(method, *args)
          @events << [ method, *args ]
        end
      end
    end
  end
end
