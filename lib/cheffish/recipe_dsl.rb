require 'cheffish'

require 'chef_zero/server'
require 'chef/chef_fs/chef_fs_data_store'
require 'chef/chef_fs/config'
require 'cheffish/chef_run_data'
require 'cheffish/chef_run_listener'
require 'chef/client'
require 'chef/config'
require 'cheffish/merged_config'

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

      def with_config(config)
        run_context.add_config_override(config)
        if block_given?
          begin
            yield
          ensure
            run_context.remove_config_override(config)
          end
        end
      end

      def with_chef_server(server_url, options = {}, &block)
        options = options.dup # Don't modify originals!
        options[:node_name] ||= options[:client_name] if options.has_key?(:client_name)
        options[:client_key] ||= options[:signing_validation_key] if options.has_key?(:signing_validation_key)
        with_config(options.merge({ :chef_server_url => server_url }), &block)
      end

      def with_chef_local_server(options, &block)
        options[:host] ||= '127.0.0.1'
        options[:log_level] ||= Chef::Log.level
        options[:port] ||= 8901

        # Create the data store chef-zero will use
        options[:data_store] ||= begin
          if !options[:chef_repo_path]
            raise "chef_repo_path must be specified to with_chef_local_server"
          end

          # Ensure all paths are given
          %w(acl client cookbook container data_bag environment group node role).each do |type|
            options["#{type}_path".to_sym] ||= begin
              if options[:chef_repo_path].kind_of?(String)
                run_context.config.path_join(options[:chef_repo_path], "#{type}s")
              else
                options[:chef_repo_path].map { |path| run_context.config.path_join(path, "#{type}s")}
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

        if block
          begin
            with_chef_server(chef_zero_server.url, &block)
          ensure
            chef_zero_server.stop
          end
        else
          with_chef_server(chef_zero_server.url)
        end
      end
    end
  end

  class Config
    default(:profile) { ENV['CHEF_PROFILE'] || 'default' }
    configurable(:private_keys)
    default(:private_key_paths) { [ path_join(config_dir, 'keys'), path_join(user_home, '.chef', 'keys'), path_join(user_home, '.ssh') ] }
    default(:private_key_write_path) { private_key_paths.first }
  end

  class RunContext
    def cheffish
      @cheffish ||= begin
        run_data = Cheffish::ChefRunData.new(self)
        events.register(Cheffish::ChefRunListener.new(self))
        run_data
      end
    end

    def base_config
      @base_config ||= Cheffish.profiled_config(Chef::Config)
    end

    def config
      @config ||= Cheffish::MergedConfig.new(base_config)
    end

    def add_config_override(config_override)
      @config = Cheffish::MergedConfig.new(config_override, *config.configs)
    end

    def remove_config_override(config_override)
      @config = Cheffish::MergedConfig.new(*(config.configs { |c| c != config_override }))
    end
  end

  Chef::Client.when_run_starts do |run_status|
    # Pulling on cheffish_run_data makes it initialize right now
    run_status.run_context.cheffish
  end

end
