require 'cheffish/resource/chef_user'
Chef::Provider::ChefUser = Chef::Resource::ChefUser.action_class
