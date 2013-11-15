class Chef::Provider::ChefClient < Cheffish::ActorProviderBase

  def whyrun_supported?
    true
  end

  def actor_type
    'client'
  end

  action :create do
    create_actor(false)
  end

  action :regenerate_keys do
    create_actor(true)
  end

  action :delete do
    delete_actor
  end

  #
  # Helpers
  #
  # Gives us new_json, current_json, not_found_json, etc.
  require 'chef/chef_fs/data_handler/client_data_handler'

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
      'validator' => :validator
    }
  end

end