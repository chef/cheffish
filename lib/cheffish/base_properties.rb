require "chef/mixin/properties"
require "cheffish/array_property"
require "cheffish"

module Cheffish
  module BaseProperties
    include Chef::Mixin::Properties

    def initialize(*args)
      super
      chef_server run_context.cheffish.current_chef_server
    end

    Boolean = property_type(is: [ true, false ])
    ArrayType = ArrayProperty.new

    property :chef_server, Hash
    property :raw_json, Hash
    property :complete, Boolean
  end
end
