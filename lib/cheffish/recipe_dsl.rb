require_relative "../cheffish"

require "chef/version"
require "chef_zero/server"
require "chef/chef_fs/chef_fs_data_store"
require "chef/chef_fs/config"
require_relative "chef_run_data"
require_relative "chef_run_listener"
require "chef/client"
require "chef/config"
require "chef_zero/version"
require_relative "merged_config"
require_relative "../chef/resource/chef_acl"
require_relative "../chef/resource/chef_client"
require_relative "../chef/resource/chef_container"
require_relative "../chef/resource/chef_data_bag"
require_relative "../chef/resource/chef_data_bag_item"
require_relative "../chef/resource/chef_environment"
require_relative "../chef/resource/chef_group"
require_relative "../chef/resource/chef_mirror"
require_relative "../chef/resource/chef_node"
require_relative "../chef/resource/chef_organization"
require_relative "../chef/resource/chef_role"
require_relative "../chef/resource/chef_user"
require_relative "../chef/resource/private_key"
require_relative "../chef/resource/public_key"
require "chef/util/path_helper"

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
        run_context.cheffish.with_chef_server({ chef_server_url: server_url, options: options }, &block)
      end

      def with_chef_local_server(options, &block)
        options[:host] ||= "127.0.0.1"
        options[:log_level] ||= Chef::Log.level
        options[:port] ||= ChefZero::VERSION.to_f >= 2.2 ? 8901.upto(9900) : 8901

        # Create the data store chef-zero will use
        options[:data_store] ||= begin
          unless options[:chef_repo_path]
            raise "chef_repo_path must be specified to with_chef_local_server"
          end

          # Ensure all paths are given
          %w{acl client cookbook container data_bag environment group node role}.each do |type|
            # Set the options as symbol keys and then copy to string keys
            string_key = "#{type}_path"
            symbol_key = "#{type}_path".to_sym

            options[symbol_key] ||= begin
              if options[:chef_repo_path].is_a?(String)
                Chef::Util::PathHelper.join(options[:chef_repo_path], "#{type}s")
              else
                options[:chef_repo_path].map { |path| Chef::Util::PathHelper.join(path, "#{type}s") }
              end
            end

            # Copy over to string keys for things that use string keys (ChefFS)...
            # TODO: Fix ChefFS to take symbols or use something that is insensitive to the difference
            options[string_key] = options[symbol_key]
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

      def get_private_key(name)
        Cheffish.get_private_key(name, run_context.config)
      end
    end
  end

  class Config
    default(:profile) { ENV["CHEF_PROFILE"] || "default" }
    configurable(:private_keys)
    default(:private_key_paths) { [ Chef::Util::PathHelper.join(config_dir, "keys"), Chef::Util::PathHelper.join(user_home, ".ssh") ] }
    default(:private_key_write_path) { private_key_paths.first }
  end

  class RunContext
    def cheffish
      node.run_state[:cheffish] ||= begin
        run_data = Cheffish::ChefRunData.new(config)
        events.register(Cheffish::ChefRunListener.new(node))
        run_data
      end
    end

    def config
      node.run_state[:chef_config] ||= Cheffish.profiled_config(Chef::Config)
    end
  end

  Chef::Client.when_run_starts do |run_status|
    # Pulling on cheffish_run_data makes it initialize right now
    run_status.node.run_state[:chef_config] = config = Cheffish.profiled_config(Chef::Config)
    run_status.node.run_state[:cheffish] = Cheffish::ChefRunData.new(config)
    run_status.events.register(Cheffish::ChefRunListener.new(run_status.node))
  end

end
