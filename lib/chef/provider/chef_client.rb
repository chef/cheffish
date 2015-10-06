require 'cheffish/resource/chef_client'
Chef::Provider::ChefClient = Chef::Resource::ChefClient.action_class
