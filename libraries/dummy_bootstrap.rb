module Cheffish
  class DummyBootstrapper
    def new_machine
      DummyMachine.new
    end

    private

    class DummyMachine
      # Setter
      def filter_node(json)
        json
      end

      def configuration_path
        '/etc/chef'
      end

      # File API
      def get_file_info(machine_path)
        result = DummyFileInfo.new
        result.exists = false
        result
      end

      def download_file(machine_path, local_path)
      end

      def upload_file(local_path, machine_path)
      end

      def set_file_owner(machine_path, owner)
      end

      def set_file_mode(machine_path, mode)
      end

      def delete_file(machine_path)
      end
    end

    class DummyFileInfo
      attr_accessor :exists
      attr_accessor :md5sum
      attr_accessor :owner
      attr_accessor :group
      attr_accessor :mode
    end
  end
end