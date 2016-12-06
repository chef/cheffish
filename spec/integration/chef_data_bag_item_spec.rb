require "support/spec_support"
require "cheffish/rspec/chef_run_support"

describe Chef::Resource::ChefDataBagItem do
  extend Cheffish::RSpec::ChefRunSupport

  when_the_chef_12_server "foo" do
    organization "foo"

    before :each do
      Chef::Config.chef_server_url = URI.join(Chef::Config.chef_server_url, "/organizations/foo").to_s
    end

    context 'when data bag "bag" exists' do
      with_converge { chef_data_bag "bag" }

      it 'runs a recipe that creates a chef_data_bag_item "bag/item"' do
        expect_recipe do
          chef_data_bag_item "bag/item"
        end.to have_updated "chef_data_bag_item[bag/item]", :create
        # expect(get('data_bags/bag')['name']).to eq('bag')
        # expect(get('data_bags/bag/item')['id']).to eq('item')
      end
    end
  end
end
