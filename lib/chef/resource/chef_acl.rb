require 'cheffish'
require 'chef/resource/lwrp_base'
require 'chef/environment'

class Chef::Resource::ChefAcl < Chef::Resource::LWRPBase
  self.resource_name = 'chef_acl'

  actions :create, :nothing
  default_action :create

  def initialize(*args)
    super
    chef_server run_context.cheffish.current_chef_server
  end

  # Path of the thing being secured, e.g. nodes, nodes/*, nodes/mynode,
  # */*, **, roles/base, data/secrets, cookbooks/apache2, /users/*,
  # /organizations/foo/nodes/x
  attribute :path, :kind_of => String, :regex => Cheffish::NAME_REGEX, :name_attribute => true

  # Whether to change things recursively.  true means it will descend all children
  # and make the same modifications to them.  :on_change will only descend if
  # the parent has changed.  :on_change is the default.
  attribute :recursive, :equal_to => [ true, false, :on_change ], :default => :on_change

  # Specifies that this is a complete specification for the acl (i.e. rights
  # you don't specify will be reset to their defaults)
  attribute :complete, :kind_of => [TrueClass, FalseClass]

  attribute :raw_json, :kind_of => Hash
  attribute :chef_server, :kind_of => Hash

  # rights :read, :users => 'jkeiser', :groups => [ 'admins', 'users' ]
  # rights [ :create, :read ], :users => [ 'jkeiser', 'adam' ]
  # rights :all, :users => 'jkeiser'
  def rights(*values)
    if values.size == 0
      @raw_json
    else
      args = values.pop
      args[:permissions] ||= []
      values.each do |value|
        args[:permissions] |= Array(value)
      end
      if args[:permissions].delete(:all)
        args[:permissions] |= [ :create, :read, :update, :delete, :grant ]
      end

      @raw_json ||= {}
      args.each_pair do |key, value|
        Array(args[:permissions]).each do |permission|
          ace = @raw_json[permission.to_s] ||= {}
          # WTF, no distinction between users and clients?  The Chef API doesn't
          # let us distinguish, so we have no choice :/  This means that:
          # 1. If you specify :users => 'foo', and client 'foo' exists, it will
          #    pick that (whether user 'foo' exists or not)
          # 2. If you specify :clients => 'foo', and user 'foo' exists but
          #    client 'foo' does not, it will pick user 'foo' and put it in the
          #    ACL
          # 3. If an existing item has user 'foo' on it and you specify :clients
          #    => 'foo' instead, idempotence will not notice that anything needs
          #    to be updated and nothing will happen.
          if args[:users]
            ace['actors'] ||= []
            ace['actors'] |= Array(args[:users])
          end
          if args[:clients]
            ace['actors'] ||= []
            ace['actors'] |= Array(args[:clients])
          end
          if args[:groups]
            ace['groups'] ||= []
            ace['groups'] |= Array(args[:groups])
          end
        end
      end
    end
  end

  # remove_rights :read, :users => 'jkeiser', :groups => [ 'admins', 'users' ]
  # remove_rights [ :create, :read ], :users => [ 'jkeiser', 'adam' ]
  # remove_rights :all, :users => [ 'jkeiser', 'adam' ]
  def remove_rights(*values)
    if values.size == 0
      @remove_rights
    else
      args = values.pop
      args[:permissions] ||= []
      values.each do |value|
        args[:permissions] |= Array(value)
      end
      if args[:permissions].delete(:all)
        args[:permissions] |= [ :create, :read, :update, :delete, :grant ]
      end

      @remove_rights ||= {}
      args.each_pair do |key, value|
        Array(args[:permissions]).each do |permission|
          ace = @remove_rights[permission.to_s] ||= {}
          # WTF, no distinction between users and clients?  The Chef API doesn't
          # let us distinguish, so we have no choice :/  This means that:
          # 1. If you specify :users => 'foo', and client 'foo' exists, it will
          #    pick that (whether user 'foo' exists or not)
          # 2. If you specify :clients => 'foo', and user 'foo' exists but
          #    client 'foo' does not, it will pick user 'foo' and put it in the
          #    ACL
          # 3. If an existing item has user 'foo' on it and you specify :clients
          #    => 'foo' instead, idempotence will not notice that anything needs
          #    to be updated and nothing will happen.
          if args[:users]
            ace['actors'] ||= []
            ace['actors'] |= Array(args[:users])
          end
          if args[:clients]
            ace['actors'] ||= []
            ace['actors'] |= Array(args[:clients])
          end
          if args[:groups]
            ace['groups'] ||= []
            ace['groups'] |= Array(args[:groups])
          end
        end
      end
    end
  end
end
