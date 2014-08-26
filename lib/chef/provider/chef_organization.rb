require 'cheffish/chef_provider_base'
require 'chef/resource/chef_organization'
require 'chef/chef_fs/data_handler/data_handler_base'

class Chef::Provider::ChefOrganization < Cheffish::ChefProviderBase

  def whyrun_supported?
    true
  end

  action :create do
    differences = json_differences(current_json, new_json)

    if current_resource_exists?
      if differences.size > 0
        description = [ "update organization #{new_resource.name} at #{rest.url}" ] + differences
        converge_by description do
          rest.put("/organizations/#{new_resource.name}", normalize_for_put(new_json))
        end
      end
    else
      description = [ "create organization #{new_resource.name} at #{rest.url}" ] + differences
      converge_by description do
        rest.post("/organizations", normalize_for_post(new_json))
      end
    end
  end

  action :delete do
    if current_resource_exists?
      converge_by "delete organization #{new_resource.name} at #{rest.url}" do
        rest.delete("/organizations/#{new_resource.name}")
      end
    end
  end

  def load_current_resource
    begin
      @current_resource = json_to_resource(rest.get("/organizations/#{new_resource.name}"))
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
