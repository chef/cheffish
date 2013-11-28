require 'support/spec_support'
require 'cheffish/recipe_dsl'
require 'chef_zero/server'
require 'cheffish/cheffish_server_api'

describe 'Recipe DSL' do
  extend SpecSupport

  when_the_chef_server 'is empty' do
    context 'and another chef server is running on port 8899' do
      before :each do
        @server = ChefZero::Server.new(port: 8899)
        @server.start_background
      end

      after :each do
        @server.stop
      end

      context 'and a recipe is run that creates node "blah" on the second chef server' do

        run_recipe_before do
          with_chef_server 'http://127.0.0.1:8899'
          chef_node 'blah'
        end

        it 'the node is created on the second chef server but not the first' do
          chef_run.should have_updated 'chef_node[blah]', :create
          lambda { get('/nodes/blah') }.should raise_error(Net::HTTPServerException)
          get('http://127.0.0.1:8899/nodes/blah')['name'].should == 'blah'
        end
      end

    end
  end
end
