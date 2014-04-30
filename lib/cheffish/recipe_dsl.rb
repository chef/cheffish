require 'cheffish'

require 'chef_zero/server'
require 'chef/chef_fs/chef_fs_data_store'
require 'chef/chef_fs/config'
require 'cheffish/chef_run_data'
require 'cheffish/chef_run_listener'
require 'chef/client'

class Chef
  module DSL
    module Recipe
      def with_chef_data_bag(name)
        run_context.cheffish.with_data_bag(name, &block)
      end

      def with_chef_environment(name, &block)
        run_context.cheffish.with_environment(name, &block)
      end

      def with_chef_data_bag_item_encryption(encryption_options, &block)
        run_context.cheffish.with_data_bag_item_encryption(encryption_options, &block)
      end

      def with_chef_server(server_url, options = {}, &block)
        run_context.cheffish.with_chef_server({ :chef_server_url => server_url, :options => options }, &block)
      end

      def with_chef_local_server(options, &block)
        options[:host] ||= '127.0.0.1'
        options[:log_level] ||= Chef::Log.level
        options[:port] ||= 8900

        # Create the data store chef-zero will use
        options[:data_store] ||= begin
          if !options[:chef_repo_path]
            raise "chef_repo_path must be specified to with_chef_local_server"
          end

          # Ensure all paths are given
          %w(acl client cookbook container data_bag environment group node role).each do |type|
            options["#{type}_path".to_sym] ||= begin
              if options[:chef_repo_path].kind_of?(String)
                Chef::Config.path_join(options[:chef_repo_path], "#{type}s")
              else
                options[:chef_repo_path].map { |path| Chef::Config.path_join(path, "#{type}s")}
              end
            end
            # Work around issue in earlier versions of ChefFS where it expects strings for these
            # instead of symbols
            options["#{type}_path"] = options["#{type}_path".to_sym]
          end

          chef_fs = Chef::ChefFS::Config.new(options).local_fs
          chef_fs.write_pretty_json = true
          Chef::ChefFS::ChefFSDataStore.new(chef_fs)
        end

        # Start the chef-zero server
        Chef::Log.info("Starting chef-zero on port #{options[:port]} with repository at #{options[:data_store].chef_fs.fs_description}")
        chef_zero_server = ChefZero::Server.new(options)
        chef_zero_server.start_background

        run_context.cheffish.local_servers << chef_zero_server

        with_chef_server(chef_zero_server.url, &block)
      end
    end
  end

  class RunContext
    def cheffish
      @cheffish ||= begin
        run_data = Cheffish::ChefRunData.new
        events.register(Cheffish::ChefRunListener.new(self))
        run_data
      end
    end
  end

  Chef::Client.when_run_starts do |run_status|
    # Pulling on cheffish_run_data makes it initialize right now
    run_status.run_context.cheffish
  end

end
