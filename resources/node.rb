actions :create, :delete, :nothing
default_action :create

attribute :name, :kind_of => String, :regex => Cheffish::NAME_REGEX, :name_attribute => true
attribute :chef_environment, :kind_of => String, :regex => Cheffish::NAME_REGEX
attribute :run_list, :kind_of => Array # We should let them specify it as a series of parameters too
attribute :default_attributes, :kind_of => Hash
attribute :normal_attributes, :kind_of => Hash
attribute :override_attributes, :kind_of => Hash
attribute :automatic_attributes, :kind_of => Hash

# Specifies that this is a complete specification for the environment (i.e. attributes you don't specify will be
# reset to their defaults)
attribute :complete, :kind_of => [TrueClass, FalseClass]

NOT_PASSED=Object.new

# default 'ip_address', '127.0.0.1'
# default [ 'pushy', 'port' ], '9000'
# default 'ip_addresses' do |existing_value|
#   (existing_value || []) + [ '127.0.0.1' ]
# end
# default 'ip_address', :delete
attr_reader :default_modifiers
def default(attribute_path, value=NOT_PASSED, &block)
  @default_modifiers ||= []
  if value != NOT_PASSED
    @default_modifiers << [ attribute_path, value ]
  elsif block
    @default_modifiers << [ attribute_path, block ]
  else
    raise "default requires either a value or a block"
  end
end

# normal 'ip_address', '127.0.0.1'
# normal [ 'pushy', 'port' ], '9000'
# normal 'ip_addresses' do |existing_value|
#   (existing_value || []) + [ '127.0.0.1' ]
# end
# normal 'ip_address', :delete
attr_reader :normal_modifiers
def normal(attribute_path, value=NOT_PASSED, &block)
  @normal_modifiers ||= []
  if value != NOT_PASSED
    @normal_modifiers << [ attribute_path, value ]
  elsif block
    @normal_modifiers << [ attribute_path, block ]
  else
    raise "normal requires either a value or a block"
  end
end

# override 'ip_address', '127.0.0.1'
# override [ 'pushy', 'port' ], '9000'
# override 'ip_addresses' do |existing_value|
#   (existing_value || []) + [ '127.0.0.1' ]
# end
# override 'ip_address', :delete
attr_reader :override_modifiers
def override(attribute_path, value=NOT_PASSED, &block)
  @override_modifiers ||= []
  if value != NOT_PASSED
    @override_modifiers << [ attribute_path, value ]
  elsif block
    @override_modifiers << [ attribute_path, block ]
  else
    raise "override requires either a value or a block"
  end
end

# automatic 'ip_address', '127.0.0.1'
# automatic [ 'pushy', 'port' ], '9000'
# automatic 'ip_addresses' do |existing_value|
#   (existing_value || []) + [ '127.0.0.1' ]
# end
# automatic 'ip_address', :delete
attr_reader :automatic_modifiers
def automatic(attribute_path, value=NOT_PASSED, &block)
  @automatic_modifiers ||= []
  if value != NOT_PASSED
    @automatic_modifiers << [ attribute_path, value ]
  elsif block
    @automatic_modifiers << [ attribute_path, block ]
  else
    raise "automatic requires either a value or a block"
  end
end

alias :attributes :normal_attributes
alias :attribute :normal

# Order matters--if two things here are in the wrong order, they will be flipped in the run list
# recipe 'apache', 'mysql'
# recipe 'recipe@version'
# recipe 'recipe'
# role ''
attr_reader :run_list_modifiers
attr_reader :run_list_removers
def recipe(*recipes)
  if recipes.size == 0
    raise ArgumentError, "At least one recipe must be specified"
  end
  @run_list_modifiers ||= []
  @run_list_modifiers += recipes.map { |recipe| Chef::RunList::RunListItem.new("recipe[#{recipe}]") }
end
def role(*roles)
  if roles.size == 0
    raise ArgumentError, "At least one role must be specified"
  end
  @run_list_modifiers ||= []
  @run_list_modifiers += roles.map { |role| Chef::RunList::RunListItem.new("role[#{role}]") }
end
def remove_recipe(*recipes)
  if recipes.size == 0
    raise ArgumentError, "At least one recipe must be specified"
  end
  @run_list_removers ||= []
  @run_list_removers += recipes.map { |recipe| Chef::RunList::RunListItem.new("recipe[#{recipe}]") }
end
def remove_role(*roles)
  if roles.size == 0
    raise ArgumentError, "At least one role must be specified"
  end
  @run_list_removers ||= []
  @run_list_removers += roles.map { |recipe| Chef::RunList::RunListItem.new("role[#{role}]") }
end
