require 'chef/environment'

actions :create, :delete, :nothing
default_action :create

attribute :name, :kind_of => String, :regex => Cheffish::NAME_REGEX, :name_attribute => true
attribute :data_bag, :kind_of => String, :regex => Cheffish::NAME_REGEX, :required => true
attribute :raw_data, :kind_of => Hash

# TODO support encryption
#attribute :encryption_key, :kind_of => String
#attribute :encryption_key_path, :kind_of => String
#attribute :encryption_version, :kind_of => Integer, :equal_to => [ 0, 1, 2 ], :default => 1

# Specifies that this is a complete specification for the environment (i.e. attributes you don't specify will be
# reset to their defaults)
attribute :complete, :kind_of => [TrueClass, FalseClass]

NOT_PASSED = Object.new

# value 'ip_address', '127.0.0.1'
# value [ 'pushy', 'port' ], '9000'
# value 'ip_addresses' do |existing_value|
#   (existing_value || []) + [ '127.0.0.1' ]
# end
# value 'ip_address', :delete
attr_reader :raw_data_modifiers
def value(raw_data_path, value=NOT_PASSED, &block)
  @raw_data_modifiers ||= []
  if value != NOT_PASSED
    @raw_data_modifiers << [ raw_data_path, value ]
  elsif block
    @raw_data_modifiers << [ raw_data_path, block ]
  else
    raise "value requires either a value or a block"
  end
end
