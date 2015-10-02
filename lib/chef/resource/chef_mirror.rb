require 'cheffish'
require 'chef_compat/resource'

class Chef
  class Resource
    class ChefMirror < ChefCompat::Resource
      resource_name :chef_mirror

      allowed_actions :upload, :download, :nothing
      default_action :nothing

      def initialize(*args)
        super
        chef_server run_context.cheffish.current_chef_server
      end

      # Path of the data to mirror, e.g. nodes, nodes/*, nodes/mynode,
      # */*, **, roles/base, data/secrets, cookbooks/apache2, etc.
      property :path, String, name_property: true

      # Local path.  Can be a string (top level of repository) or hash
      # (:chef_repo_path, :node_path, etc.)
      # If neither chef_repo_path nor versioned_cookbooks are set, they default to their
      # Chef::Config values.  If chef_repo_path is set but versioned_cookbooks is not,
      # versioned_cookbooks defaults to true.
      property :chef_repo_path, [ String, Hash ]

      # Whether the repo path should contain cookbooks with versioned names,
      # i.e. cookbooks/mysql-1.0.0, cookbooks/mysql-1.2.0, etc.
      # Defaults to true if chef_repo_path is specified, or to Chef::Config.versioned_cookbooks otherwise.
      property :versioned_cookbooks, [ true, false ]

      # Chef server
      property :chef_server, Hash

      # Whether to purge deleted things: if we do not have cookbooks/x locally and we
      # *do* have cookbooks/x remotely, then :upload with purge will delete it.
      # Defaults to false.
      property :purge, [ true, false ]

      # Whether to freeze cookbooks on upload
      property :freeze, [ true, false ]

      # If this is true, only new files will be copied.  File contents will not be
      # diffed, so changed files will never be uploaded.
      property :no_diff, [ true, false ]

      # Number of parallel threads to list/upload/download with.  Defaults to 10.
      property :concurrency, Integer
    end
  end
end
