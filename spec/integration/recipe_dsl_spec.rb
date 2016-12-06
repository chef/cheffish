require "support/spec_support"
require "cheffish/rspec/chef_run_support"
require "tmpdir"

describe "Cheffish Recipe DSL" do
  extend Cheffish::RSpec::ChefRunSupport

  context "when we include with_chef_local_server" do
    before :each do
      @tmp_repo = tmp_repo = Dir.mktmpdir("chef_repo")
    end

    after :each do
      FileUtils.remove_entry_secure @tmp_repo
    end

    it "chef_nodes get put into said server" do
      tmp_repo = @tmp_repo
      expect_recipe do
        with_chef_local_server :chef_repo_path => tmp_repo
        chef_node "blah"
      end.to have_updated "chef_node[blah]", :create
      expect(File).to exist("#{@tmp_repo}/nodes/blah.json")
    end
  end
end
