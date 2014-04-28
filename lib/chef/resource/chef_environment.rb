require 'cheffish'
require 'chef/resource/lwrp_base'
require 'chef/environment'

class Chef::Resource::ChefEnvironment < Chef::Resource::LWRPBase
  self.resource_name = 'chef_environment'

  actions :create, :delete, :nothing
  default_action :create

  def initialize(*args)
    super
    chef_server run_context.cheffish.current_chef_server
  end

  attribute :name, :kind_of => String, :regex => Cheffish::NAME_REGEX, :name_attribute => true
  attribute :description, :kind_of => String
  attribute :cookbook_versions, :kind_of => Hash, :callbacks => {
    "should have valid cookbook versions" => lambda { |value| Chef::Environment.validate_cookbook_versions(value) }
  }
  attribute :default_attributes, :kind_of => Hash
  attribute :override_attributes, :kind_of => Hash

  # Specifies that this is a complete specification for the environment (i.e. attributes you don't specify will be
  # reset to their defaults)
  attribute :complete, :kind_of => [TrueClass, FalseClass]

  attribute :raw_json, :kind_of => Hash
  attribute :chef_server, :kind_of => Hash

  NOT_PASSED=Object.new

  # default 'ip_address', '127.0.0.1'
  # default [ 'pushy', 'port' ], '9000'
  # default 'ip_addresses' do |existing_value|
  #   (existing_value || []) + [ '127.0.0.1' ]
  # end
  # default 'ip_address', :delete
  attr_reader :default_attribute_modifiers
  def default(attribute_path, value=NOT_PASSED, &block)
    @default_attribute_modifiers ||= []
    if value != NOT_PASSED
      @default_attribute_modifiers << [ attribute_path, value ]
    elsif block
      @default_attribute_modifiers << [ attribute_path, block ]
    else
      raise "default requires either a value or a block"
    end
  end

  # override 'ip_address', '127.0.0.1'
  # override [ 'pushy', 'port' ], '9000'
  # override 'ip_addresses' do |existing_value|
  #   (existing_value || []) + [ '127.0.0.1' ]
  # end
  # override 'ip_address', :delete
  attr_reader :override_attribute_modifiers
  def override(attribute_path, value=NOT_PASSED, &block)
    @override_attribute_modifiers ||= []
    if value != NOT_PASSED
      @override_attribute_modifiers << [ attribute_path, value ]
    elsif block
      @override_attribute_modifiers << [ attribute_path, block ]
    else
      raise "override requires either a value or a block"
    end
  end

  alias :attributes :default_attributes
  alias :attribute :default
end
