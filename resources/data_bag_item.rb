require 'chef/environment'

def initialize(*args)
  super
  name @name
end

def name(*args)
  result = super(*args)
  if args.size == 1
    parts = name.split('/')
    if parts.size == 1
      @id = parts[0]
    elsif parts.size == 2
      @data_bag = parts[0]
      @id = parts[1]
    else
      raise "Name #{args[0].inspect} must be a string with 1 or 2 parts, either 'id' or 'data_bag/id"
    end
  end
  result
end

actions :create, :delete, :nothing
default_action :create

NOT_PASSED = Object.new
def id(value = NOT_PASSED)
  if value == NOT_PASSED
    @id
  else
    @id = value
    name data_bag ? "#{data_bag}/#{id}" : id
  end
end
def data_bag(value = NOT_PASSED)
  if value == NOT_PASSED
    @data_bag
  else
    @data_bag = value
    name data_bag ? "#{data_bag}/#{id}" : id
  end
end
attribute :raw_data, :kind_of => Hash

# TODO support encryption
#attribute :encryption_key, :kind_of => String
#attribute :encryption_key_path, :kind_of => String
#attribute :encryption_version, :kind_of => Integer, :equal_to => [ 0, 1, 2 ], :default => 1

# Specifies that this is a complete specification for the environment (i.e. attributes you don't specify will be
# reset to their defaults)
attribute :complete, :kind_of => [TrueClass, FalseClass]

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
