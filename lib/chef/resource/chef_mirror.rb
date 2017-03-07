require "cheffish"
require "cheffish/base_resource"
require "chef/chef_fs/file_pattern"
require "chef/chef_fs/file_system"
require "chef/chef_fs/parallelizer"
require "chef/chef_fs/file_system/chef_server/chef_server_root_dir"
require "chef/chef_fs/file_system/repository/chef_repository_file_system_root_dir"

class Chef
  class Resource
    class ChefMirror < Cheffish::BaseResource
      resource_name :chef_mirror

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
      property :versioned_cookbooks, Boolean

      # Whether to purge deleted things: if we do not have cookbooks/x locally and we
      # *do* have cookbooks/x remotely, then :upload with purge will delete it.
      # Defaults to false.
      property :purge, Boolean

      # Whether to freeze cookbooks on upload
      property :freeze_on_upload, Boolean

      # `freeze` is an already-existing instance method on Object, so we can't use it or we'll throw
      # a deprecation warning. `freeze` has been renamed to `freeze_on_upload` and this method
      # is here to log a deprecation warning.
      def freeze(arg = nil)
        Chef::Log.warn("Property `freeze` on the `chef_mirror` resource has changed to `freeze_on_upload`." \
          "Please use `freeze_on_upload` instead. This will raise an exception in a future version of the cheffish gem.")

        set_or_return(
          :freeze_on_upload,
          arg,
          :kind_of => Boolean
        )
      end

      # If this is true, only new files will be copied.  File contents will not be
      # diffed, so changed files will never be uploaded.
      property :no_diff, Boolean

      # Number of parallel threads to list/upload/download with.  Defaults to 10.
      property :concurrency, Integer, default: 10, desired_state: false

      action :upload do
        with_modified_config do
          copy_to(local_fs, remote_fs)
        end
      end

      action :download do
        with_modified_config do
          copy_to(remote_fs, local_fs)
        end
      end

      action_class.class_eval do

        def with_modified_config
          # pre-Chef-12 ChefFS reads versioned_cookbooks out of Chef::Config instead of
          # taking it as an input, so we need to modify it for the duration of copy_to
          @old_versioned_cookbooks = Chef::Config.versioned_cookbooks
          # If versioned_cookbooks is explicitly set, set it.
          if !new_resource.versioned_cookbooks.nil?
            Chef::Config.versioned_cookbooks = new_resource.versioned_cookbooks

          # If new_resource.chef_repo_path is set, versioned_cookbooks defaults to true.
          # Otherwise, it stays at its current Chef::Config value.
          elsif new_resource.chef_repo_path
            Chef::Config.versioned_cookbooks = true
          end

          begin
            yield
          ensure
            Chef::Config.versioned_cookbooks = @old_versioned_cookbooks
          end
        end

        def copy_to(src_root, dest_root)
          if new_resource.concurrency <= 0
            raise "chef_mirror.concurrency must be above 0!  Was set to #{new_resource.concurrency}"
          end
          # Honor concurrency
          Chef::ChefFS::Parallelizer.threads = new_resource.concurrency - 1

          # We don't let the user pass absolute paths; we want to reserve those for
          # multi-org support (/organizations/foo).
          if new_resource.path[0] == "/"
            raise "Absolute paths in chef_mirror not yet supported."
          end
          # Copy!
          path = Chef::ChefFS::FilePattern.new("/#{new_resource.path}")
          ui = CopyListener.new(self)
          error = Chef::ChefFS::FileSystem.copy_to(path, src_root, dest_root, nil, options, ui, proc { |p| p.path })

          if error
            raise "Errors while copying:#{ui.errors.map { |e| "#{e}\n" }.join('')}"
          end
        end

        def local_fs
          # If chef_repo_path is set to a string, put it in the form it usually is in
          # chef config (:chef_repo_path, :node_path, etc.)
          path_config = new_resource.chef_repo_path
          if path_config.is_a?(Hash)
            chef_repo_path = path_config.delete(:chef_repo_path)
          elsif path_config
            chef_repo_path = path_config
            path_config = {}
          else
            chef_repo_path = Chef::Config.chef_repo_path
            path_config = Chef::Config
          end
          chef_repo_path = Array(chef_repo_path).flatten

          # Go through the expected object paths and figure out the local paths for each.
          case repo_mode
          when "hosted_everything"
            object_names = %w{acls clients cookbooks containers data_bags environments groups nodes roles}
          else
            object_names = %w{clients cookbooks data_bags environments nodes roles users}
          end

          object_paths = {}
          object_names.each do |object_name|
            variable_name = "#{object_name[0..-2]}_path" # cookbooks -> cookbook_path
            if path_config[variable_name.to_sym]
              paths = Array(path_config[variable_name.to_sym]).flatten
            else
              paths = chef_repo_path.map { |path| ::File.join(path, object_name) }
            end
            object_paths[object_name] = paths.map { |path| ::File.expand_path(path) }
          end

          # Set up the root dir
          Chef::ChefFS::FileSystem::Repository::ChefRepositoryFileSystemRootDir.new(object_paths)
        end

        def remote_fs
          config = {
            :chef_server_url => new_resource.chef_server[:chef_server_url],
            :node_name => new_resource.chef_server[:options][:client_name],
            :client_key => new_resource.chef_server[:options][:signing_key_filename],
            :repo_mode => repo_mode,
            :versioned_cookbooks => Chef::Config.versioned_cookbooks,
          }
          Chef::ChefFS::FileSystem::ChefServer::ChefServerRootDir.new("remote", config)
        end

        def repo_mode
          new_resource.chef_server[:chef_server_url] =~ /\/organizations\// ? "hosted_everything" : "everything"
        end

        def options
          result = {
            :purge => new_resource.purge,
            :freeze => new_resource.freeze_on_upload,
            :diff => new_resource.no_diff,
            :dry_run => whyrun_mode?,
          }
          result[:diff] = !result[:diff]
          result[:repo_mode] = repo_mode
          result[:concurrency] = new_resource.concurrency if new_resource.concurrency
          result
        end

        def load_current_resource
        end

        class CopyListener
          def initialize(mirror)
            @mirror = mirror
            @errors = []
          end

          attr_reader :mirror
          attr_reader :errors

          # TODO output is not *always* indicative of a change.  We may want to give
          # ChefFS the ability to tell us that info.  For now though, assuming any output
          # means change is pretty damn close to the truth.
          def output(str)
            mirror.converge_by str do
            end
          end

          def warn(str)
            mirror.converge_by "WARNING: #{str}" do
            end
          end

          def error(str)
            mirror.converge_by "ERROR: #{str}" do
            end
            @errors << str
          end
        end
      end
    end
  end
end
