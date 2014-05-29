require 'chef/config'
require 'cheffish/with_pattern'

module Cheffish
  class ChefRunData
    def initialize(run_context)
      @local_servers = []
    end

    extend Cheffish::WithPattern
    with :data_bag
    with :environment
    with :data_bag_item_encryption

    attr_reader :local_servers
  end
end
