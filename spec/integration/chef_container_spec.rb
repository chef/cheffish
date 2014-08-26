require 'support/spec_support'
require 'chef/resource/chef_container'
require 'chef/provider/chef_container'

describe Chef::Resource::ChefContainer do
  extend SpecSupport

  when_the_chef_server 'is empty', :osc_compat => false do
    it 'Converging chef_container "x" creates the container' do
      run_recipe do
        chef_container 'x'
      end
      expect(chef_run).to have_updated('chef_container[x]', :create)
    end
  end

  when_the_chef_server 'has a container named x', :osc_compat => false do
    container 'x', {}

    it 'Converging chef_container "x" changes nothing' do
      run_recipe do
        chef_container 'x'
      end
      expect(chef_run).not_to have_updated('chef_container[x]', :create)
    end
  end
end
