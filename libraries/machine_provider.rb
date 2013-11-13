class Chef::Provider::Machine < Cheffish::ChefProviderBase

  use_inline_resources

  def whyrun_supported?
    true
  end

  action :create do
    # Create the node
    chef_node new_resource.name do
      chef_environment new_resource.chef_environment
      run_list new_resource.run_list
      default_attributes new_resource.default_attributes
      normal_attributes new_resource.normal_attributes
      override_attributes new_resource.override_attributes
      automatic_attributes new_resource.automatic_attributes
      default_modifiers = new_resource.default_modifiers
      normal_modifiers = new_resource.normal_modifiers
      override_modifiers = new_resource.override_modifiers
      automatic_modifiers = new_resource.automatic_modifiers
      run_list_modifiers = new_resource.run_list_modifiers
      run_list_removers = new_resource.run_list_removers
      complete new_resource.complete
    end

    # TODO get the public key out of the remote node so we can fix if it's broke
    public_key = new_resource.public_key_path
    private_key = new_resource.private_key_path

    # Create or update the client
    chef_client new_resource.name do
      public_key_path public_key
      private_key_path private_key
    end

    # Create the machine if it does not exist

    # Get chef-client on the machine if it does not exist

    # Trigger a converge if any of the previous things caused changes
  end

  action :delete do
    chef_client new_resource.name do
      action :delete
    end
    chef_node new_resource.name do
      action :delete
    end
  end

  def load_current_resource
  end
end
