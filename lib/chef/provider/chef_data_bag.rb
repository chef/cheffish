require 'cheffish/chef_provider_base'
require 'chef/resource/chef_data_bag'

class Chef::Provider::ChefDataBag < Cheffish::ChefProviderBase
  provides :chef_data_bag

  def whyrun_supported?
    true
  end

  action :create do
    if !current_resource_exists?
      converge_by "create data bag #{new_resource.name} at #{rest.url}" do
        rest.post("data", { 'name' => new_resource.name })
      end
    end
  end

  action :delete do
    if current_resource_exists?
      converge_by "delete data bag #{new_resource.name} at #{rest.url}" do
        rest.delete("data/#{new_resource.name}")
      end
    end
  end

  def load_current_resource
    begin
      @current_resource = json_to_resource(rest.get("data/#{new_resource.name}"))
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
  # Gives us new_json, current_json, not_found_json, etc.

  def resource_class
    Chef::Resource::ChefDataBag
  end

  def json_to_resource(json)
    Chef::Resource::ChefDataBag.new(json['name'], run_context)
  end
end
