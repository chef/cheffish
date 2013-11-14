class Chef::Provider::Machine < Cheffish::ChefProviderBase

  use_inline_resources

  def whyrun_supported?
    true
  end

  action :create do
    new_machine = new_resource.bootstrapper.new_machine

    # Create the node
    chef_node new_resource.name do
      chef_environment new_resource.chef_environment
      run_list new_resource.run_list
      default_attributes new_resource.default_attributes
      normal_attributes new_resource.normal_attributes
      override_attributes new_resource.override_attributes
      automatic_attributes new_resource.automatic_attributes
      self.default_modifiers = new_resource.default_modifiers
      self.normal_modifiers = new_resource.normal_modifiers
      self.override_modifiers = new_resource.override_modifiers
      self.automatic_modifiers = new_resource.automatic_modifiers
      self.run_list_modifiers = new_resource.run_list_modifiers
      self.run_list_removers = new_resource.run_list_removers
      complete new_resource.complete
      filter { |node| new_machine.filter_node(node) }

#      notifies :converge, "machine_converge[#{new_resource.name}]"
    end

    # TODO don't make a tempfile path, download to a string
    if new_resource.private_key_path
      tempfile = nil
      private_key_path = new_resource.private_key_path
    else
      tempfile = Tempfile.new('private_key')
      private_key_path = tempfile.path
    end

    begin
      # Get the remote pem so we can avoid disturbing the key unnecessarily
      machine_file "#{new_machine.configuration_path}/#{new_resource.name}.pem" do
        machine new_machine
        source private_key_path
        delete_if_missing true
        action :copy_to_source
      end

      # Create or update the client
      chef_client new_resource.name do
        public_key_path new_resource.public_key_path
        private_key_path private_key_path
        admin new_resource.admin
        validator new_resource.validator
        key_owner true
  #      notifies :converge, "machine_converge[#{new_resource.name}]"
      end

      #
      # Create the machine
      #
  #    raw_machine new_resource.name, new_machine do
  #      notifies :converge, "machine_converge[#{new_resource.name}]"
  #    end

      #
      # Configure the client
      #
  #    machine_configuration new_resource.name, new_machine do
  #      client_name new_resource.name
  #      client_key new_resource.private_key_path
  #      extra_files new_resource.extra_files
  #      notifies :converge, "machine_converge[#{new_resource.name}]"
  #    end

      # Converge the client if anything changed
  #    converge_machine new_resource.name, new_machine do
  #      action :nothing
  #    end
    ensure
      tempfile.unlink if tempfile
    end
  end

  action :delete do
    new_machine = bootstrapper.machine(chef_server_url, new_resource.chef_environment, new_resource.name)

    # Destroy the machine
    raw_machine new_resource.name, new_machine do
      action :delete
    end

    chef_client new_resource.name do
      action :delete
    end
    chef_node new_resource.name do
      action :delete
    end
  end

  def load_current_resource
    # This is basically a meta-resource; the inner resources do all the heavy lifting
  end
end
