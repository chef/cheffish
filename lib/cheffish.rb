module Cheffish
  NAME_REGEX = /^[.\-[:alnum:]_]+$/

  def self.inline_resource(provider, provider_action, *resources, &block)
    BasicChefClient.inline_resource(provider, provider_action, *resources, &block)
  end

  def self.default_chef_server(config = profiled_config)
    {
      :chef_server_url => config[:chef_server_url],
      :options => {
        :client_name => config[:node_name],
        :signing_key_filename => config[:client_key],
      },
    }
  end

  def self.chef_server_api(chef_server = default_chef_server)
    # Pin the server api version to 0 until https://github.com/chef/cheffish/issues/56
    # gets the correct compatibility fix.
    chef_server[:options] ||= {}
    chef_server[:options][:api_version] = "0"
    Cheffish::ServerAPI.new(chef_server[:chef_server_url], chef_server[:options])
  end

  def self.profiled_config(config = Chef::Config)
    if config.profile && config.profiles && config.profiles[config.profile]
      MergedConfig.new(config.profiles[config.profile], config)
    else
      config
    end
  end

  def self.load_chef_config(chef_config = Chef::Config)
    if ::Gem::Version.new(::Chef::VERSION) >= ::Gem::Version.new("12.0.0")
      chef_config.config_file = ::Chef::Knife.chef_config_dir
    else
      chef_config.config_file = ::Chef::Knife.locate_config_file
    end
    config_fetcher = Chef::ConfigFetcher.new(chef_config.config_file, chef_config.config_file_jail)
    if chef_config.config_file.nil?
      Chef::Log.warn("No config file found or specified on command line, using command line options.")
    elsif config_fetcher.config_missing?
      Chef::Log.warn("Did not find config file: #{chef_config.config_file}, using command line options.")
    else
      config_content = config_fetcher.read_config
      config_file_path = chef_config.config_file
      begin
        chef_config.from_string(config_content, config_file_path)
      rescue Exception => error
        Chef::Log.fatal("Configuration error #{error.class}: #{error.message}")
        filtered_trace = error.backtrace.grep(/#{Regexp.escape(config_file_path)}/)
        filtered_trace.each { |line| Chef::Log.fatal("  " + line ) }
        Chef::Application.fatal!("Aborting due to error in '#{config_file_path}'", 2)
      end
    end
    Cheffish.profiled_config(chef_config)
  end

  def self.honor_local_mode(local_mode_default = true, &block)
    if !Chef::Config.has_key?(:local_mode) && !local_mode_default.nil?
      Chef::Config.local_mode = local_mode_default
    end
    if Chef::Config.local_mode && !Chef::Config.has_key?(:cookbook_path) && !Chef::Config.has_key?(:chef_repo_path)
      Chef::Config.chef_repo_path = Chef::Config.find_chef_repo_path(Dir.pwd)
    end
    begin
      require "chef/local_mode"
      Chef::LocalMode.with_server_connectivity(&block)

    rescue LoadError
      Chef::Application.setup_server_connectivity
      if block_given?
        begin
          yield
        ensure
          Chef::Application.destroy_server_connectivity
        end
      end
    end
  end

  def self.get_private_key(name, config = profiled_config)
    key, key_path = get_private_key_with_path(name, config)
    key
  end

  def self.get_private_key_with_path(name, config = profiled_config)
    if config[:private_keys] && config[:private_keys][name]
      named_key = config[:private_keys][name]
      if named_key.is_a?(String)
        Chef::Log.info("Got key #{name} from Chef::Config.private_keys.#{name}, which points at #{named_key}.  Reading key from there ...")
        return [ IO.read(named_key), named_key]
      else
        Chef::Log.info("Got key #{name} raw from Chef::Config.private_keys.#{name}.")
        return [ named_key.to_pem, nil ]
      end
    elsif config[:private_key_paths]
      config[:private_key_paths].each do |private_key_path|
        next unless File.exist?(private_key_path)
        Dir.entries(private_key_path).sort.each do |key|
          ext = File.extname(key)
          if key == name || ext == "" || ext == ".pem"
            key_name = key[0..-(ext.length + 1)]
            if key_name == name || key == name
              Chef::Log.info("Reading key #{name} from file #{private_key_path}/#{key}")
              return [ IO.read("#{private_key_path}/#{key}"), "#{private_key_path}/#{key}" ]
            end
          end
        end
      end
    end
    nil
  end

  def self.node_attributes(klass)
    klass.include Cheffish::NodeProperties
  end
end

# Include all recipe objects so require 'cheffish' brings in the whole recipe DSL

require "chef/run_list/run_list_item"
require "cheffish/basic_chef_client"
require "cheffish/server_api"
require "chef/knife"
require "chef/config_fetcher"
require "chef/log"
require "chef/application"
require "cheffish/recipe_dsl"
require "cheffish/node_properties"
