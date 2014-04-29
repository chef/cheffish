require 'chef/config'
require 'cheffish/with_pattern'

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

    extend Cheffish::WithPattern
    with :data_bag
    with :environment
    with :data_bag_item_encryption
    with :chef_server

    attr_reader :local_servers
  end
end
