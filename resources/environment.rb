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

# TODO Patchy methods: setting these will patch up attributes without deleting things (unless complete is specified)
# cookbook_version 'apache', '= 1.0.0'
# cookbook_version 'apache', :delete
# default_attribute 'ip_address', '127.0.0.1'
# default_attribute 'ip_address', :delete
# override_attribute 'ip_address', '127.0.0.1'
# override_attribute [ 'pushy', 'port' ], '8000'

# Control options
attribute :complete, :kind_of => [TrueClass, FalseClass]
