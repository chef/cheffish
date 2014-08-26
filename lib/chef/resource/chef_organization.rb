require 'cheffish'
require 'chef/resource/lwrp_base'
require 'chef/run_list/run_list_item'

class Chef::Resource::ChefOrganization < Chef::Resource::LWRPBase
  self.resource_name = 'chef_organization'

  actions :create, :delete, :nothing
  default_action :create

  # Grab environment from with_environment
  def initialize(*args)
    super
    chef_server run_context.cheffish.current_chef_server
    @invites = nil
    @members = nil
    @remove_members = []
  end

  attribute :name, :kind_of => String, :regex => Cheffish::NAME_REGEX, :name_attribute => true
  attribute :full_name, :kind_of => String

  # A list of users who must at least be invited to the org (but may already be
  # members).  Invites will be sent to users who are not already invited/in the org.
  def invites(*users)
    if users.size == 0
      @invites || []
    else
      @invites ||= []
      @invites |= users.flatten
    end
  end

  def invites_specified?
    !!@invites
  end

  # A list of users who must be members of the org.  This will use the new Chef 12
  # POST /organizations/ORG/users/NAME endpoint to add them directly to the org.
  # If you do not have permission to perform this operation, and the users are not
  # a part of the org, the resource update will fail.
  def members(*users)
    if users.size == 0
      @members || []
    else
      @members ||= []
      @members |= users.flatten
    end
  end

  def members_specified?
    !!@members
  end

  # A list of users who must not be members of the org.  These users will be removed
  # from the org and invites will be revoked (if any).
  def remove_members(*users)
    users.size == 0 ? @remove_members : (@remove_members |= users.flatten)
  end

  attribute :complete, :kind_of => [ TrueClass, FalseClass ]
  attribute :raw_json, :kind_of => Hash
  attribute :chef_server, :kind_of => Hash
end
