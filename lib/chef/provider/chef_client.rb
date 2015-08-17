require 'cheffish/actor_provider_base'
require 'chef/resource/chef_client'
require 'chef/chef_fs/data_handler/client_data_handler'

class Chef::Provider::ChefClient < Cheffish::ActorProviderBase
  provides :chef_client

  def whyrun_supported?
    true
  end

  def actor_type
    'client'
  end

  def actor_path
    'clients'
  end

  action :create do
    create_actor
  end

  action :delete do
    delete_actor
  end

  #
  # Helpers
  #

  def resource_class
    Chef::Resource::ChefClient
  end

  def data_handler
    Chef::ChefFS::DataHandler::ClientDataHandler.new
  end

  def keys
    {
      'name' => :name,
      'admin' => :admin,
      'validator' => :validator,
      'public_key' => :source_key
    }
  end

end
