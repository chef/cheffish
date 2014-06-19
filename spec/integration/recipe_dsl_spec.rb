require 'support/spec_support'
require 'chef/resource/chef_node'
require 'chef/provider/chef_node'
require 'tmpdir'

describe 'Cheffish Recipe DSL' do
  extend SpecSupport

  context 'when we include with_chef_local_server' do
    before :each do
      @tmp_repo = tmp_repo = Dir.mktmpdir('chef_repo')
      load_recipe do
        with_chef_local_server :chef_repo_path => tmp_repo
      end
    end

    after :each do
      FileUtils.remove_entry_secure @tmp_repo
    end

    it 'chef_nodes get put into said server' do
      run_recipe do
        chef_node 'blah'
      end
      expect(chef_run).to have_updated 'chef_node[blah]', :create
      expect(File).to exist("#{@tmp_repo}/nodes/blah.json")
    end
  end
end
