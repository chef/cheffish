require 'chef/environment'

actions :create, :delete, :nothing
default_action :create

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

NOT_PASSED=Object.new

# default_attribute 'ip_address', '127.0.0.1'
# default_attribute [ 'pushy', 'port' ], '9000'
# default_attribute 'ip_addresses' do |existing_value|
#   (existing_value || []) + [ '127.0.0.1' ]
# end
# default_attribute 'ip_address', :delete
attr_reader :default_attribute_modifiers
def default_attribute(attribute_path, value=NOT_PASSED, &block)
  @default_attribute_modifiers ||= []
  if value != NOT_PASSED
    @default_attribute_modifiers << [ attribute_path, value ]
  elsif block
    @default_attribute_modifiers << [ attribute_path, block ]
  else
    raise "default_attribute requires either a value or a block"
  end
end

# override_attribute 'ip_address', '127.0.0.1'
# override_attribute [ 'pushy', 'port' ], '9000'
# override_attribute 'ip_addresses' do |existing_value|
#   (existing_value || []) + [ '127.0.0.1' ]
# end
# override_attribute 'ip_address', :delete
attr_reader :override_attribute_modifiers
def override_attribute(attribute_path, value=NOT_PASSED, &block)
  @override_attribute_modifiers ||= []
  if value != NOT_PASSED
    @override_attribute_modifiers << [ attribute_path, value ]
  elsif block
    @override_attribute_modifiers << [ attribute_path, block ]
  else
    raise "override_attribute requires either a value or a block"
  end
end
