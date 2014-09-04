require 'support/spec_support'
require 'chef/resource/chef_container'
require 'chef/provider/chef_container'

describe Chef::Resource::ChefContainer do
  extend SpecSupport

  when_the_chef_server 'is in multi-org mode', :osc_compat => false, :single_org => false do
    organization 'foo'

    before :each do
      Chef::Config.chef_server_url = URI.join(Chef::Config.chef_server_url, '/organizations/foo').to_s
    end

    it 'Converging chef_container "x" creates the container' do
      run_recipe do
        chef_container 'x'
      end
      expect(chef_run).to have_updated('chef_container[x]', :create)
      expect { get('containers/x') }.not_to raise_error
    end

    context 'and already has a container named x' do
      container 'x', {}

      it 'Converging chef_container "x" changes nothing' do
        run_recipe do
          chef_container 'x'
        end
        expect(chef_run).not_to have_updated('chef_container[x]', :create)
      end
    end
  end
end
