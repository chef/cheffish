require 'support/spec_support'
require 'cheffish/rspec/chef_run_support'
require 'chef/resource/chef_container'
require 'chef/provider/chef_container'

describe Chef::Resource::ChefContainer do
  extend Cheffish::RSpec::ChefRunSupport

  when_the_chef_12_server 'is in multi-org mode' do
    organization 'foo'

    before :each do
      Chef::Config.chef_server_url = URI.join(Chef::Config.chef_server_url, '/organizations/foo').to_s
    end

    it 'Converging chef_container "x" creates the container' do
      expect_recipe {
        chef_container 'x'
      }.to have_updated('chef_container[x]', :create)
      expect { get('containers/x') }.not_to raise_error
    end

    context 'and already has a container named x' do
      container 'x', {}

      it 'Converging chef_container "x" changes nothing' do
        expect_recipe {
          chef_container 'x'
        }.not_to have_updated('chef_container[x]', :create)
      end
    end
  end
end
