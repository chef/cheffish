require 'support/spec_support'
require 'chef/resource/chef_organization'
require 'chef/provider/chef_organization'

describe Chef::Resource::ChefOrganization do
  extend SpecSupport

  when_the_chef_server 'is empty', :osc_compat => false, :single_org => false do
    it 'Converging chef_organization "x" creates the organization' do
      run_recipe do
        chef_organization 'x'
      end
      expect(chef_run).to have_updated('chef_organization[x]', :create)
      expect(get('/organizations/x')['full_name']).to eq('x')
    end

    it 'Converging chef_organization "x" with full_name creates the organization' do
      run_recipe do
        chef_organization 'x' do
          full_name 'Hi'
        end
      end
      expect(chef_run).to have_updated('chef_organization[x]', :create)
      expect(get('/organizations/x')['full_name']).to eq('Hi')
    end
  end

  when_the_chef_server 'has an organization named x', :osc_compat => false, :single_org => false do
    organization 'x', { 'full_name' => 'Lo' }

    it 'Converging chef_organization "x" changes nothing' do
      run_recipe do
        chef_organization 'x'
      end
      expect(chef_run).not_to have_updated('chef_organization[x]', :create)
      expect(get('/organizations/x')['full_name']).to eq('Lo')
    end

    it 'Converging chef_organization "x" with "complete true" reverts the full_name' do
      run_recipe do
        chef_organization 'x' do
          complete true
        end
      end
      expect(chef_run).to have_updated('chef_organization[x]', :create)
      expect(get('/organizations/x')['full_name']).to eq('x')
    end

    it 'Converging chef_organization "x" with new full_name updates the organization' do
      run_recipe do
        chef_organization 'x' do
          full_name 'Hi'
        end
      end
      expect(chef_run).to have_updated('chef_organization[x]', :create)
      expect(get('/organizations/x')['full_name']).to eq('Hi')
    end
  end
end
