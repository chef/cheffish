class Chef::Resource::MachineFile < Chef::Resource::LWRPBase
  self.resource_name = 'machine_file'

  actions :create, :delete, :copy_to_source, :nothing
  default_action :create

  Cheffish.node_attributes(self)

  attribute :path, :kind_of => String, :name_attribute => true
  attribute :machine
  attribute :source, :kind_of => String
  attribute :owner
  attribute :group
  attribute :mode

  # Delete the target file if the source file is missing (reverses for copy_to_source)
  attribute :delete_if_missing, :kind_of => [TrueClass, FalseClass]
end
