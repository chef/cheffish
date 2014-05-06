require 'support/spec_support'
require 'chef/resource/chef_node'
require 'chef/provider/chef_node'

describe Chef::Resource::ChefNode do
  extend SpecSupport

  when_the_chef_server 'is empty' do
    context 'and we run a recipe that creates node "blah"' do
      with_converge do
        chef_node 'blah'
      end

      it 'the node gets created' do
        chef_run.should have_updated 'chef_node[blah]', :create
        get('/nodes/blah')['name'].should == 'blah'
      end
    end

    # TODO why-run mode

    context 'and another chef server is running on port 8899' do
      before :each do
        @server = ChefZero::Server.new(:port => 8899)
        @server.start_background
      end

      after :each do
        @server.stop
      end

      context 'and a recipe is run that creates node "blah" on the second chef server using with_chef_server' do

        with_converge do
          with_chef_server 'http://127.0.0.1:8899'
          chef_node 'blah'
        end

        it 'the node is created on the second chef server but not the first' do
          chef_run.should have_updated 'chef_node[blah]', :create
          lambda { get('/nodes/blah') }.should raise_error(Net::HTTPServerException)
          get('http://127.0.0.1:8899/nodes/blah')['name'].should == 'blah'
        end
      end

      context 'and a recipe is run that creates node "blah" on the second chef server using chef_server' do

        with_converge do
          chef_node 'blah' do
            chef_server({ :chef_server_url => 'http://127.0.0.1:8899' })
          end
        end

        it 'the node is created on the second chef server but not the first' do
          chef_run.should have_updated 'chef_node[blah]', :create
          lambda { get('/nodes/blah') }.should raise_error(Net::HTTPServerException)
          get('http://127.0.0.1:8899/nodes/blah')['name'].should == 'blah'
        end
      end

    end
  end

  when_the_chef_server 'has a node named "blah"' do
    node 'blah', {}

    with_converge do
      chef_node 'blah'
    end

    it 'chef_node "blah" does not get created or updated' do
      chef_run.should_not have_updated 'chef_node[blah]', :create
    end
  end

  when_the_chef_server 'has a node named "blah" with tags' do
    node 'blah', {
      'normal' => { 'tags' => [ 'a', 'b' ] }
    }

    context 'with chef_node "blah" that sets attributes' do
      with_converge do
        chef_node 'blah' do
          attributes({})
        end
      end

      it 'the tags in attributes are used' do
        get('/nodes/blah')['normal']['tags'].should == [ 'a', 'b' ]
      end
    end

    context 'with chef_node "blah" that sets attributes with tags in them' do
      with_converge do
        chef_node 'blah' do
          attributes 'tags' => [ 'c', 'd' ]
        end
      end

      it 'the tags in attributes are used' do
        get('/nodes/blah')['normal']['tags'].should == [ 'c', 'd' ]
      end
    end
  end

  when_the_chef_server 'has a node named "blah" with everything in it' do
    node 'blah', {
      'chef_environment' => 'blah',
      'run_list'  => [ 'recipe[bjork]' ],
      'normal'    => { 'foo' => 'bar', 'tags' => [ 'a', 'b' ] },
      'default'   => { 'foo2' => 'bar2' },
      'automatic' => { 'foo3' => 'bar3' },
      'override'  => { 'foo4' => 'bar4' }
    }

    context 'with chef_node "blah"' do
      with_converge do
        chef_node 'blah'
      end

      it 'nothing gets updated' do
        chef_run.should_not have_updated 'chef_node[blah]', :create
      end
    end

    context 'with chef_node "blah" with complete true' do
      with_converge do
        chef_node 'blah' do
          complete true
        end
      end

      it 'default, automatic and override attributes are left alone' do
        chef_run.should have_updated 'chef_node[blah]', :create
        node = get('/nodes/blah')
        node['chef_environment'].should == '_default'
        node['run_list'].should == []
        node['normal'].should == { 'tags' => [ 'a', 'b' ] }
        node['default'].should == { 'foo2' => 'bar2' }
        node['automatic'].should == { 'foo3' => 'bar3' }
        node['override'].should == { 'foo4' => 'bar4' }
      end
    end
  end
end
