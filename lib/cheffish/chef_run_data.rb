require 'chef/config'
require 'cheffish/with_pattern'

module Cheffish
  class ChefRunData
    def initialize
      @local_servers = []
      @current_chef_server = Cheffish.default_chef_server
    end

    extend Cheffish::WithPattern
    with :data_bag
    with :environment
    with :data_bag_item_encryption
    with :chef_server

    attr_reader :local_servers
  end
end
