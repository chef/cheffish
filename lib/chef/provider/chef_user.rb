require 'cheffish/actor_provider_base'
require 'chef/resource/chef_user'
require 'chef/chef_fs/data_handler/user_data_handler'

class Chef::Provider::ChefUser < Cheffish::ActorProviderBase

  def whyrun_supported?
    true
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

  def actor_type
    'user'
  end

  def resource_class
    Chef::Resource::ChefUser
  end

  def data_handler
    Chef::ChefFS::DataHandler::UserDataHandler.new
  end

  def keys
    {
      'name' => :name,
      'admin' => :admin,
      'email' => :email,
      'password' => :password,
      'external_authentication_uid' => :external_authentication_uid,
      'recovery_authentication_enabled' => :recovery_authentication_enabled
    }
  end

end