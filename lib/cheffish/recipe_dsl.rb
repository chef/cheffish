require 'cheffish'

require 'chef_zero/server'
require 'chef/chef_fs/chef_fs_data_store'
require 'chef/chef_fs/config'

class Chef
  class Recipe
    def with_chef_data_bag(name)
      old_enclosing_data_bag = Cheffish.enclosing_data_bag
      Cheffish.enclosing_data_bag = name
      if block_given?
        begin
          yield
        ensure
          Cheffish.enclosing_data_bag = old_enclosing_data_bag
        end
      end
    end

    def with_chef_environment(name)
      old_enclosing_environment = Cheffish.enclosing_environment
      Cheffish.enclosing_environment = name
      if block_given?
        begin
          yield
        ensure
          Cheffish.enclosing_environment = old_enclosing_environment
        end
      end
    end

    def with_chef_data_bag_item_encryption(encryption_options)
      old_enclosing_data_bag_item_encryption = Cheffish.enclosing_data_bag_item_encryption
      Cheffish.enclosing_data_bag_item_encryption = encryption_options
      if block_given?
        begin
          yield
        ensure
          Cheffish.enclosing_data_bag_item_encryption = old_enclosing_data_bag_item_encryption
        end
      end
    end

    def with_chef_server(server_url, options = {})
      old_enclosing_chef_server = Cheffish.enclosing_chef_server
      Cheffish.enclosing_chef_server = { :chef_server_url => server_url, :options => options }
      if block_given?
        begin
          yield
        ensure
          Cheffish.enclosing_chef_server = old_enclosing_chef_server
        end
      end
    end

    def with_chef_local_server(options, &block)
      # By default, finds the computer's ip address and binds to it
      options[:host] ||= '127.0.0.1'
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

        # Create the data store chef-zero will use
        chef_fs = Chef::ChefFS::Config.new(options).local_fs
        chef_fs.write_pretty_json = true
        Chef::ChefFS::ChefFSDataStore.new(chef_fs)
      end
      options[:log_level] ||= Chef::Log.level
      options[:port] ||= 8900
      Chef::Log.info("Starting chef-zero on port #{options[:port]} with repository at #{options[:data_store].chef_fs.fs_description}")
      chef_zero_server = ChefZero::Server.new(options)
      chef_zero_server.start_background
      Chef::Config.chef_server_url = chef_zero_server.url

      @@local_servers ||= []
      @@local_servers << chef_zero_server

      with_chef_server(chef_zero_server.url, &block)
    end
  end
end
