require 'chef/provider/lwrp_base'
require 'chef/chef_fs/file_pattern'
require 'chef/chef_fs/file_system'
require 'chef/chef_fs/parallelizer'
require 'chef/chef_fs/file_system/chef_server_root_dir'
require 'chef/chef_fs/file_system/chef_repository_file_system_root_dir'

class Chef::Provider::ChefMirror < Chef::Provider::LWRPBase

  def whyrun_supported?
    true
  end

  action :upload do
    copy_to(local_fs, remote_fs)
  end

  action :download do
    copy_to(remote_fs, local_fs)
  end

  def copy_to(src_root, dest_root)
    # Honor concurrency
    Chef::ChefFS::Parallelizer.threads = (new_resource.concurrency || 10) - 1

    # We don't let the user pass absolute paths; we want to reserve those for
    # multi-org support (/organizations/foo).
    if new_resource.path[0] == '/'
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
    elsif chef_repo_path
      chef_repo_path = path_config
      path_config = {}
    else
      chef_repo_path = Chef::Config.chef_repo_path
      path_config = Chef::Config
    end
    chef_repo_path = Array(chef_repo_path).flatten

    # Go through the expected object paths and figure out the local paths for each.
    object_paths = {}
    case repo_mode
    when 'hosted_everything'
      object_names = %w(acls clients cookbooks containers data_bags environments groups nodes roles)
    else
      object_names = %w(clients cookbooks data_bags environments nodes roles users)
    end
    object_names.each do |object_name|
      variable_name = "#{object_name[0..-2]}_path" # cookbooks -> cookbook_path
      if path_config[variable_name]
        paths = Array(path_config[variable_name]).flatten
      else
        paths = chef_repo_path.map { |path| ::File.join(path, object_name) }
      end
      object_paths[object_name] = paths.map { |path| ::File.expand_path(path) }
    end

    # Set up the root dir
    Chef::ChefFS::FileSystem::ChefRepositoryFileSystemRootDir.new(object_paths)
  end

  def remote_fs
    config = {
      :chef_server_url => new_resource.chef_server[:chef_server_url],
      :node_name => new_resource.chef_server[:options][:client_name],
      :client_key => new_resource.chef_server[:options][:client_key],
      :repo_mode => repo_mode
    }
    Chef::ChefFS::FileSystem::ChefServerRootDir.new("remote", config)
  end

  def repo_mode
    new_resource.chef_server[:chef_server_url] =~ /\/organizations\// ? 'hosted_everything' : 'everything'
  end

  def options
    result = {
      :purge => new_resource.purge,
      :freeze => new_resource.freeze,
      :diff => new_resource.no_diff,
      :dry_run => whyrun_mode?
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
