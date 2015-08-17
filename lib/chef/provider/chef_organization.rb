require 'cheffish/chef_provider_base'
require 'chef/resource/chef_organization'
require 'chef/chef_fs/data_handler/data_handler_base'

class Chef::Provider::ChefOrganization < Cheffish::ChefProviderBase
  provides :chef_organization

  def whyrun_supported?
    true
  end

  action :create do
    differences = json_differences(current_json, new_json)

    if current_resource_exists?
      if differences.size > 0
        description = [ "update organization #{new_resource.name} at #{rest.url}" ] + differences
        converge_by description do
          rest.put("#{rest.root_url}/organizations/#{new_resource.name}", normalize_for_put(new_json))
        end
      end
    else
      description = [ "create organization #{new_resource.name} at #{rest.url}" ] + differences
      converge_by description do
        rest.post("#{rest.root_url}/organizations", normalize_for_post(new_json))
      end
    end

    # Revoke invites and memberships when asked
    invites_to_remove.each do |user|
      if outstanding_invites.has_key?(user)
        converge_by "revoke #{user}'s invitation to organization #{new_resource.name}" do
          rest.delete("#{rest.root_url}/organizations/#{new_resource.name}/association_requests/#{outstanding_invites[user]}")
        end
      end
    end
    members_to_remove.each do |user|
      if existing_members.include?(user)
        converge_by "remove #{user} from organization #{new_resource.name}" do
          rest.delete("#{rest.root_url}/organizations/#{new_resource.name}/users/#{user}")
        end
      end
    end

    # Invite and add members when asked
    new_resource.invites.each do |user|
      if !existing_members.include?(user) && !outstanding_invites.has_key?(user)
        converge_by "invite #{user} to organization #{new_resource.name}" do
          rest.post("#{rest.root_url}/organizations/#{new_resource.name}/association_requests", { 'user' => user })
        end
      end
    end
    new_resource.members.each do |user|
      if !existing_members.include?(user)
        converge_by "Add #{user} to organization #{new_resource.name}" do
          rest.post("#{rest.root_url}/organizations/#{new_resource.name}/users/#{user}", {})
        end
      end
    end
  end

  def existing_members
    @existing_members ||= rest.get("#{rest.root_url}/organizations/#{new_resource.name}/users").map { |u| u['user']['username'] }
  end

  def outstanding_invites
    @outstanding_invites ||= begin
      invites = {}
      rest.get("#{rest.root_url}/organizations/#{new_resource.name}/association_requests").each do |r|
        invites[r['username']] = r['id']
      end
      invites
    end
  end

  def invites_to_remove
    if new_resource.complete
      if new_resource.invites_specified? || new_resource.members_specified?
        outstanding_invites.keys - (new_resource.invites | new_resource.members)
      else
        []
      end
    else
      new_resource.remove_members
    end
  end

  def members_to_remove
    if new_resource.complete
      if new_resource.members_specified?
        existing_members - (new_resource.invites | new_resource.members)
      else
        []
      end
    else
      new_resource.remove_members
    end
  end

  action :delete do
    if current_resource_exists?
      converge_by "delete organization #{new_resource.name} at #{rest.url}" do
        rest.delete("#{rest.root_url}/organizations/#{new_resource.name}")
      end
    end
  end

  def load_current_resource
    begin
      @current_resource = json_to_resource(rest.get("#{rest.root_url}/organizations/#{new_resource.name}"))
    rescue Net::HTTPServerException => e
      if e.response.code == "404"
        @current_resource = not_found_resource
      else
        raise
      end
    end
  end

  #
  # Helpers
  #

  def resource_class
    Chef::Resource::ChefOrganization
  end

  def data_handler
    OrganizationDataHandler.new
  end

  def keys
    {
      'name' => :name,
      'full_name' => :full_name
    }
  end

  class OrganizationDataHandler < Chef::ChefFS::DataHandler::DataHandlerBase
    def normalize(organization, entry)
      # Normalize the order of the keys for easier reading
      normalize_hash(organization, {
        'name' => remove_dot_json(entry.name),
        'full_name' => remove_dot_json(entry.name),
        'org_type' => 'Business',
        'clientname' => "#{remove_dot_json(entry.name)}-validator",
        'billing_plan' => 'platform-free'
      })
    end
  end
end
