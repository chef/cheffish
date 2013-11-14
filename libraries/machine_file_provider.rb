require 'chef/digester'

class Chef::Provider::MachineFile < Cheffish::ChefProviderBase

  def whyrun_supported?
    true
  end

  action :create do
    # Upload file
    if Array(current_resource.action) == [ :delete ] && !::File.exist?(new_resource.source) && new_resource.delete_if_missing
      converge_by("delete #{new_resource.path} on #{new_resource.machine.to_s} since local source is missing") do
        new_resource.machine.delete_file(new_resource.path)
      end
      return
    end

    if Array(current_resource.action) == [ :delete ]
      action = 'create'
    else
      if new_sha != current_sha
        action = 'update'
      end
    end
    if action
      converge_by("#{action} #{new_resource.path} on #{new_resource.machine.to_s} from #{new_resource.source}") do
        new_resource.machine.upload_file(new_resource.source, new_resource.path)
      end
    end

    # Set owner, group and mode
    if new_resource.owner && new_resource.owner != current_resource.owner
      converge_by("set owner of #{new_resource.path} on #{new_resource.machine.to_s} to #{new_resource.owner}") do
        new_resource.machine.set_file_owner(new_resource.path, new_resource.owner)
      end
    end
    if new_resource.group && new_resource.group != current_resource.group
      converge_by("set group of #{new_resource.path} on #{new_resource.machine.to_s} to #{new_resource.group}") do
        new_resource.machine.set_file_group(new_resource.path, new_resource.group)
      end
    end
    if new_resource.mode && new_resource.mode != current_resource.mode
      converge_by("set mode of #{new_resource.path} on #{new_resource.machine.to_s} to #{new_resource.mode}") do
        new_resource.machine.set_file_owner(new_resource.path, new_resource.mode)
      end
    end
  end

  action :delete do
    # Delete file
    if Array(current_resource.action) != [ :delete ]
      converge_by("delete #{new_resource.path} on #{new_resource.machine.to_s}") do
        new_resource.machine.delete_file(new_resource.path)
      end
    end
  end

  action :copy_to_source do
    if ::File.exist?(new_resource.source)
      if Array(current_resource.action) == [ :delete ] && new_resource.delete_if_missing
        converge_by("delete #{new_resource.source} because target file does not exist") do
          ::File.unlink(new_resource.source)
        end
      elsif new_sha == current_sha
        action = 'update'
      end
    else
      action = 'create'
    end

    if action
      converge_by("#{action} #{new_resource.source} from #{new_resource.path} on #{new_resource.machine.to_s}") do
        new_resource.machine.download_file(new_resource.path, new_resource.source)
      end
    end
  end

  attr_reader :current_sha

  def new_sha
    @new_sha ||= Chef::Digester.generate_md5_checksum_for_file(*args)
  end

  def load_current_resource
    result = Chef::Resource::MachineFile.new(new_resource.path)
    result.machine new_resource.machine
    result.source new_resource.source

    # Check for existence and get file info
    info = new_resource.machine.get_file_info(new_resource.path)
    if !info.exists
      result.action :delete
    else
      result.owner info.owner
      result.group info.group
      result.mode info.mode
      @current_sha = info.md5sum
    end
    @current_resource = result
  end
end
