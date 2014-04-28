require 'chef/config'

module Cheffish
  class ChefRunData
    def initialize
      @local_servers = []
      @current_chef_server = {
        :chef_server_url => Chef::Config[:chef_server_url],
        :options => {
          :client_name => Chef::Config[:node_name],
          :signing_key_filename => Chef::Config[:client_key]
        }
      }
    end

    attr_accessor :current_data_bag
    attr_accessor :current_environment
    attr_accessor :current_data_bag_item_encryption
    attr_accessor :current_chef_server
    attr_reader :local_servers
  end
end
