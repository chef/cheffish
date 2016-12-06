require "cheffish"
require "cheffish/base_resource"
require "chef/run_list/run_list_item"
require "chef/chef_fs/data_handler/data_handler_base"

class Chef
  class Resource
    class ChefOrganization < Cheffish::BaseResource
      resource_name :chef_organization

      property :organization_name, Cheffish::NAME_REGEX, name_property: true
      property :full_name, String

      # A list of users who must at least be invited to the org (but may already be
      # members).  Invites will be sent to users who are not already invited/in the org.
      property :invites, ArrayType

      # A list of users who must be members of the org.  This will use the
      # new Chef 12 POST /organizations/ORG/users endpoint to add them
      # directly to the org.  If you do not have permission to perform
      # this operation, and the users are not a part of the org, the
      # resource update will fail.
      property :members, ArrayType

      # A list of users who must not be members of the org.  These users will be removed
      # from the org and invites will be revoked (if any).
      property :remove_members, ArrayType

      action :create do
        differences = json_differences(current_json, new_json)

        if current_resource_exists?
          if differences.size > 0
            description = [ "update organization #{new_resource.organization_name} at #{rest.url}" ] + differences
            converge_by description do
              rest.put("#{rest.root_url}/organizations/#{new_resource.organization_name}", normalize_for_put(new_json))
            end
          end
        else
          description = [ "create organization #{new_resource.organization_name} at #{rest.url}" ] + differences
          converge_by description do
            rest.post("#{rest.root_url}/organizations", normalize_for_post(new_json))
          end
        end

        # Revoke invites and memberships when asked
        invites_to_remove.each do |user|
          if outstanding_invites.has_key?(user)
            converge_by "revoke #{user}'s invitation to organization #{new_resource.organization_name}" do
              rest.delete("#{rest.root_url}/organizations/#{new_resource.organization_name}/association_requests/#{outstanding_invites[user]}")
            end
          end
        end
        members_to_remove.each do |user|
          if existing_members.include?(user)
            converge_by "remove #{user} from organization #{new_resource.organization_name}" do
              rest.delete("#{rest.root_url}/organizations/#{new_resource.organization_name}/users/#{user}")
            end
          end
        end

        # Invite and add members when asked
        new_resource.invites.each do |user|
          if !existing_members.include?(user) && !outstanding_invites.has_key?(user)
            converge_by "invite #{user} to organization #{new_resource.organization_name}" do
              rest.post("#{rest.root_url}/organizations/#{new_resource.organization_name}/association_requests", { "user" => user })
            end
          end
        end
        new_resource.members.each do |user|
          if !existing_members.include?(user)
            converge_by "Add #{user} to organization #{new_resource.organization_name}" do
              rest.post("#{rest.root_url}/organizations/#{new_resource.organization_name}/users/", { "username" => user })
            end
          end
        end
      end

      action_class.class_eval do
        def existing_members
          @existing_members ||= rest.get("#{rest.root_url}/organizations/#{new_resource.organization_name}/users").map { |u| u["user"]["username"] }
        end

        def outstanding_invites
          @outstanding_invites ||= begin
            invites = {}
            rest.get("#{rest.root_url}/organizations/#{new_resource.organization_name}/association_requests").each do |r|
              invites[r["username"]] = r["id"]
            end
            invites
          end
        end

        def invites_to_remove
          if new_resource.complete
            if new_resource.property_is_set?(:invites) || new_resource.property_is_set?(:members)
              result = outstanding_invites.keys
              result -= new_resource.invites if new_resource.property_is_set?(:invites)
              result -= new_resource.members if new_resource.property_is_set?(:members)
              result
            else
              []
            end
          else
            new_resource.remove_members
          end
        end

        def members_to_remove
          if new_resource.complete
            if new_resource.property_is_set?(:members)
              existing_members - (new_resource.invites | new_resource.members)
            else
              []
            end
          else
            new_resource.remove_members
          end
        end
      end

      action :delete do
        if current_resource_exists?
          converge_by "delete organization #{new_resource.organization_name} at #{rest.url}" do
            rest.delete("#{rest.root_url}/organizations/#{new_resource.organization_name}")
          end
        end
      end

      action_class.class_eval do
        def load_current_resource
          begin
            @current_resource = json_to_resource(rest.get("#{rest.root_url}/organizations/#{new_resource.organization_name}"))
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
            "name" => :organization_name,
            "full_name" => :full_name,
          }
        end

        class OrganizationDataHandler < Chef::ChefFS::DataHandler::DataHandlerBase
          def normalize(organization, entry)
            # Normalize the order of the keys for easier reading
            normalize_hash(organization, {
              "name" => remove_dot_json(entry.name),
              "full_name" => remove_dot_json(entry.name),
              "org_type" => "Business",
              "clientname" => "#{remove_dot_json(entry.name)}-validator",
              "billing_plan" => "platform-free",
            })
          end
        end
      end

    end
  end
end
