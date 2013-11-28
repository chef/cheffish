require 'support/spec_support'
require 'chef/resource/chef_node'
require 'chef/provider/chef_node'

describe Chef::Resource::ChefNode do
  extend SpecSupport

  when_the_chef_server 'is empty' do
    context 'and we run a recipe that creates node "blah"' do
      run_recipe_before do
        chef_node 'blah'
      end

      it 'the node gets created' do
        chef_run.should have_updated 'chef_node[blah]', :create
        get('/nodes/blah')['name'].should == 'blah'
      end
    end

    # why-run mode
  end

  when_the_chef_server 'has a node named "blah"' do
    node 'blah', {}

    run_recipe_before do
      chef_node 'blah'
    end

    it 'the node "blah" does not get created or updated' do
      chef_run.should_not have_updated 'chef_node[blah]', :create
    end
  end
end
