require "chef/mixin/properties"
require_relative "array_property"
require_relative "../cheffish"

module Cheffish
  module BaseProperties
    include Chef::Mixin::Properties

    def initialize(*args)
      super
      chef_server run_context.cheffish.current_chef_server
    end

    ArrayType = ArrayProperty.new

    property :chef_server, Hash
    property :raw_json, Hash
    property :complete, [TrueClass, FalseClass]
  end
end
