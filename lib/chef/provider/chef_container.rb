require 'cheffish/chef_provider_base'
require 'chef/resource/chef_container'
require 'chef/chef_fs/data_handler/container_data_handler'

class Chef::Provider::ChefContainer < Cheffish::ChefProviderBase
  provides :chef_container

  def whyrun_supported?
    true
  end

  action :create do
    if !@current_exists
      converge_by "create container #{new_resource.name} at #{rest.url}" do
        rest.post("containers", normalize_for_post(new_json))
      end
    end
  end

  action :delete do
    if @current_exists
      converge_by "delete container #{new_resource.name} at #{rest.url}" do
        rest.delete("containers/#{new_resource.name}")
      end
    end
  end

  def load_current_resource
    begin
      @current_exists = rest.get("containers/#{new_resource.name}")
    rescue Net::HTTPServerException => e
      if e.response.code == "404"
        @current_exists = false
      else
        raise
      end
    end
  end

  def new_json
    {}
  end

  def data_handler
    Chef::ChefFS::DataHandler::ContainerDataHandler.new
  end

  def keys
    { 'containername' => :name, 'containerpath' => :name }
  end
end
