require "support/spec_support"
require "cheffish/rspec/chef_run_support"

describe Chef::Resource::ChefMirror do
  extend Cheffish::RSpec::ChefRunSupport

  when_the_chef_12_server "is in multi-org mode" do
    organization "foo"

    before :each do
      Chef::Config.chef_server_url = URI.join(Chef::Config.chef_server_url, "/organizations/foo").to_s
    end

    describe "basic download and upload" do
      when_the_repository "is full of stuff" do
        file "nodes/x.json", {}
        file "roles/x.json", {}
        directory "cookbooks/x" do
          file "metadata.rb", 'name "x"; version "2.0.0"'
        end

        it "Download grabs defaults" do
          expect_recipe do
            chef_mirror "" do
              action :download
            end
          end.to have_updated("chef_mirror[]", :download)
          expect(File.exist?(path_to("groups/admins.json"))).to be true
          expect(File.exist?(path_to("environments/_default.json"))).to be true
        end

        it "Upload uploads everything" do
          expect_recipe do
            chef_mirror "" do
              action :upload
            end
          end.to have_updated("chef_mirror[]", :upload)
          expect { get("nodes/x") }.not_to raise_error
          expect { get("roles/x") }.not_to raise_error
          expect { get("cookbooks/x/2.0.0") }.not_to raise_error
        end

        it "chef_mirror with concurrency 0 fails with a reasonable message" do
          expect do
            converge do
              chef_mirror "" do
                concurrency 0
                action :download
              end
            end
          end.to raise_error /chef_mirror.concurrency must be above 0/
        end
      end
    end

    context "and the Chef server has a node and role in it" do
      node "x", {}
      role "x", {}

      when_the_repository "is empty" do
        it "Download grabs the node and role" do
          expect_recipe do
            chef_mirror "" do
              action :download
            end
          end.to have_updated("chef_mirror[]", :download)
          expect(File.exist?(path_to("nodes/x.json"))).to be true
          expect(File.exist?(path_to("roles/x.json"))).to be true
        end

        it "Upload uploads nothing" do
          expect_recipe do
            chef_mirror "" do
              action :upload
            end
          end.not_to have_updated("chef_mirror[]", :upload)
        end
      end
    end

    context "and the Chef server has nodes and roles named x" do
      node "x", {}
      role "x", {}

      when_the_repository "has nodes and roles named y" do
        file "nodes/y.json", {}
        file "roles/y.json", {}

        it "Download grabs the x's" do
          expect_recipe do
            chef_mirror "" do
              action :download
            end
          end.to have_updated("chef_mirror[]", :download)
          expect(File.exist?(path_to("nodes/x.json"))).to be true
          expect(File.exist?(path_to("roles/x.json"))).to be true
          expect(File.exist?(path_to("nodes/y.json"))).to be true
          expect(File.exist?(path_to("roles/y.json"))).to be true
        end

        it "Upload uploads the y's" do
          expect_recipe do
            chef_mirror "" do
              action :upload
            end
          end.to have_updated("chef_mirror[]", :upload)
          expect { get("nodes/x") }.not_to raise_error
          expect { get("roles/x") }.not_to raise_error
          expect { get("nodes/y") }.not_to raise_error
          expect { get("roles/y") }.not_to raise_error
        end

        it "Download with purge grabs the x's and deletes the y's" do
          expect_recipe do
            chef_mirror "" do
              purge true
              action :download
            end
          end.to have_updated("chef_mirror[]", :download)
          expect(File.exist?(path_to("nodes/x.json"))).to be true
          expect(File.exist?(path_to("roles/x.json"))).to be true
        end

        it "Upload with :purge uploads the y's and deletes the x's" do
          expect_recipe do
            chef_mirror "*/*.json" do
              purge true
              action :upload
            end
          end.to have_updated("chef_mirror[*/*.json]", :upload)
          expect { get("nodes/y") }.not_to raise_error
          expect { get("roles/y") }.not_to raise_error
        end
      end
    end

    describe "chef_repo_path" do
      when_the_repository "has stuff but no chef_repo_path" do
        file "repo/nodes/x.json", {}
        file "repo/roles/x.json", {}
        file "repo2/nodes/y.json", {}
        file "repo2/roles/y.json", {}

        before do
          Chef::Config.delete(:chef_repo_path)
          Chef::Config.delete(:node_path)
          Chef::Config.delete(:cookbook_path)
          Chef::Config.delete(:role_path)
        end

        it "Upload with chef_repo_path('repo') uploads everything" do
          repo_path = path_to("repo")
          expect_recipe do
            chef_mirror "" do
              chef_repo_path repo_path
              action :upload
            end
          end.to have_updated("chef_mirror[]", :upload)
          expect { get("nodes/x") }.not_to raise_error
          expect { get("roles/x") }.not_to raise_error
          expect { get("nodes/y") }.to raise_error /404/
          expect { get("roles/y") }.to raise_error /404/
        end

        it "Upload with chef_repo_path(:chef_repo_path) with multiple paths uploads everything" do
          repo_path = path_to("repo")
          repo2_path = path_to("repo2")
          expect_recipe do
            chef_mirror "" do
              chef_repo_path :chef_repo_path => [ repo_path, repo2_path ]
              action :upload
            end
          end.to have_updated("chef_mirror[]", :upload)
          expect { get("nodes/x") }.not_to raise_error
          expect { get("roles/x") }.not_to raise_error
          expect { get("nodes/y") }.not_to raise_error
          expect { get("roles/y") }.not_to raise_error
        end

        it "Upload with chef_repo_path(:node_path, :role_path) uploads everything" do
          repo_path = path_to("repo")
          repo2_path = path_to("repo2")

          expect_recipe do
            chef_mirror "" do
              chef_repo_path :chef_repo_path => "/blahblah",
                             :node_path => "#{repo_path}/nodes",
                             :role_path => "#{repo2_path}/roles"
              action :upload
            end
          end.to have_updated("chef_mirror[]", :upload)
          expect { get("nodes/x") }.not_to raise_error
          expect { get("roles/x") }.to raise_error /404/
          expect { get("nodes/y") }.to raise_error /404/
          expect { get("roles/y") }.not_to raise_error
        end

        it "Upload with chef_repo_path(:chef_repo_path, :role_path) uploads everything" do
          repo_path = path_to("repo")
          repo2_path = path_to("repo2")

          expect_recipe do
            chef_mirror "" do
              chef_repo_path :chef_repo_path => repo_path,
                             :role_path => "#{repo2_path}/roles"
              action :upload
            end
          end.to have_updated("chef_mirror[]", :upload)
          expect { get("nodes/x") }.not_to raise_error
          expect { get("roles/x") }.to raise_error /404/
          expect { get("nodes/y") }.to raise_error /404/
          expect { get("roles/y") }.not_to raise_error
        end

        it "Upload with chef_repo_path(:node_path, :role_path) with multiple paths uploads everything" do
          repo_path = path_to("repo")
          repo2_path = path_to("repo2")

          expect_recipe do
            chef_mirror "" do
              chef_repo_path :chef_repo_path => %w{foo bar},
                             :node_path => [ "#{repo_path}/nodes", "#{repo2_path}/nodes" ],
                             :role_path => [ "#{repo_path}/roles", "#{repo2_path}/roles" ]
              action :upload
            end
          end.to have_updated("chef_mirror[]", :upload)
          expect { get("nodes/x") }.not_to raise_error
          expect { get("roles/x") }.not_to raise_error
          expect { get("nodes/y") }.not_to raise_error
          expect { get("roles/y") }.not_to raise_error
        end
      end
    end

    describe "cookbook upload, chef_repo_path and versioned_cookbooks" do
      when_the_repository "has cookbooks in non-versioned format" do
        file "cookbooks/x-1.0.0/metadata.rb", 'name "x-1.0.0"; version "2.0.0"'
        file "cookbooks/y-1.0.0/metadata.rb", 'name "y-3.0.0"; version "4.0.0"'

        it "chef_mirror :upload uploads everything" do
          expect_recipe do
            chef_mirror "" do
              action :upload
            end
          end.to have_updated("chef_mirror[]", :upload)
          expect { get("cookbooks/x-1.0.0/2.0.0") }.not_to raise_error
          expect { get("cookbooks/y-3.0.0/4.0.0") }.not_to raise_error
        end

        context "and Chef::Config.versioned_cookbooks is false" do
          before do
            Chef::Config.versioned_cookbooks false
          end
          it "chef_mirror :upload uploads everything" do
            expect_recipe do
              chef_mirror "" do
                action :upload
              end
            end.to have_updated("chef_mirror[]", :upload)
            expect { get("cookbooks/x-1.0.0/2.0.0") }.not_to raise_error
            expect { get("cookbooks/y-3.0.0/4.0.0") }.not_to raise_error
          end
        end

        context "and Chef::Config.chef_repo_path is not set but versioned_cookbooks is false" do
          before do
            Chef::Config.delete(:chef_repo_path)
            Chef::Config.versioned_cookbooks false
          end

          it "chef_mirror :upload with chef_repo_path and versioned_cookbooks false uploads cookbooks with name including version" do
            repository_dir = @repository_dir
            expect_recipe do
              chef_mirror "" do
                chef_repo_path repository_dir
                versioned_cookbooks false
                action :upload
              end
            end.to have_updated("chef_mirror[]", :upload)
            expect { get("cookbooks/x-1.0.0/2.0.0") }.not_to raise_error
            expect { get("cookbooks/y-3.0.0/4.0.0") }.not_to raise_error
          end
        end
      end

      when_the_repository "has cookbooks in versioned_cookbook format" do
        file "cookbooks/x-1.0.0/metadata.rb", 'name "x"; version "1.0.0"'
        file "cookbooks/x-2.0.0/metadata.rb", 'name "x"; version "2.0.0"'

        context "and Chef::Config.versioned_cookbooks is true" do
          before do
            Chef::Config.versioned_cookbooks true
          end
          it "chef_mirror :upload uploads everything" do
            expect_recipe do
              chef_mirror "" do
                action :upload
              end
            end.to have_updated("chef_mirror[]", :upload)
            expect { get("cookbooks/x/1.0.0") }.not_to raise_error
            expect { get("cookbooks/x/2.0.0") }.not_to raise_error
          end
        end

        context "and Chef::Config.chef_repo_path set somewhere else" do
          before do
            Chef::Config.chef_repo_path = "/x/y/z"
          end
          it "chef_mirror :upload with chef_repo_path uploads cookbooks" do
            repository_dir = @repository_dir
            expect_recipe do
              chef_mirror "" do
                chef_repo_path repository_dir
                action :upload
              end
            end.to have_updated("chef_mirror[]", :upload)
            expect { get("cookbooks/x/1.0.0") }.not_to raise_error
            expect { get("cookbooks/x/2.0.0") }.not_to raise_error
          end
        end

        context "and Chef::Config.chef_repo_path is not set but versioned_cookbooks is false" do
          before do
            Chef::Config.delete(:chef_repo_path)
            Chef::Config.versioned_cookbooks false
          end

          it "chef_mirror :upload with chef_repo_path uploads cookbooks with name split from version" do
            repository_dir = @repository_dir
            expect_recipe do
              chef_mirror "" do
                chef_repo_path repository_dir
                action :upload
              end
            end.to have_updated("chef_mirror[]", :upload)
            expect { get("cookbooks/x/1.0.0") }.not_to raise_error
            expect { get("cookbooks/x/2.0.0") }.not_to raise_error
          end

          it "chef_mirror :upload with chef_repo_path and versioned_cookbooks uploads cookbooks with name split from version" do
            repository_dir = @repository_dir
            expect_recipe do
              chef_mirror "" do
                chef_repo_path repository_dir
                versioned_cookbooks true
                action :upload
              end
            end.to have_updated("chef_mirror[]", :upload)
            expect { get("cookbooks/x/1.0.0") }.not_to raise_error
            expect { get("cookbooks/x/2.0.0") }.not_to raise_error
          end
        end

        context "and Chef::Config.chef_repo_path is not set but versioned_cookbooks is true" do
          before do
            Chef::Config.delete(:chef_repo_path)
            Chef::Config.versioned_cookbooks true
          end
          it "chef_mirror :upload with chef_repo_path uploads cookbooks with name split from version" do
            repository_dir = @repository_dir
            expect_recipe do
              chef_mirror "" do
                chef_repo_path repository_dir
                action :upload
              end
            end.to have_updated("chef_mirror[]", :upload)
            expect { get("cookbooks/x/1.0.0") }.not_to raise_error
            expect { get("cookbooks/x/2.0.0") }.not_to raise_error
          end
        end
      end
    end

    describe "cookbook download, chef_repo_path, and versioned_cookbooks" do
      context "when the Chef server has a cookbook with multiple versions" do
        cookbook "x", "1.0.0", "metadata.rb" => 'name "x"; version "1.0.0"'
        cookbook "x", "2.0.0", "metadata.rb" => 'name "x"; version "2.0.0"'

        when_the_repository "is empty" do
          it "chef_mirror :download downloads the latest version of the cookbook" do
            expect_recipe do
              chef_mirror "" do
                action :download
              end
            end.to have_updated("chef_mirror[]", :download)
            expect(File.read(path_to("cookbooks/x/metadata.rb"))).to eq('name "x"; version "2.0.0"')
          end

          it "chef_mirror :download with versioned_cookbooks = true downloads all versions of the cookbook" do
            expect_recipe do
              chef_mirror "" do
                versioned_cookbooks true
                action :download
              end
            end.to have_updated("chef_mirror[]", :download)
            expect(File.read(path_to("cookbooks/x-1.0.0/metadata.rb"))).to eq('name "x"; version "1.0.0"')
            expect(File.read(path_to("cookbooks/x-2.0.0/metadata.rb"))).to eq('name "x"; version "2.0.0"')
          end

          context "and Chef::Config.chef_repo_path is set elsewhere" do
            before do
              Chef::Config.chef_repo_path = "/x/y/z"
            end

            it "chef_mirror :download with chef_repo_path downloads all versions of the cookbook" do
              repository_dir = @repository_dir
              expect_recipe do
                chef_mirror "" do
                  chef_repo_path repository_dir
                  action :download
                end
              end.to have_updated("chef_mirror[]", :download)
              expect(File.read(path_to("cookbooks/x-1.0.0/metadata.rb"))).to eq('name "x"; version "1.0.0"')
              expect(File.read(path_to("cookbooks/x-2.0.0/metadata.rb"))).to eq('name "x"; version "2.0.0"')
            end

            it "chef_mirror :download with chef_repo_path and versioned_cookbooks = false downloads the latest version of the cookbook" do
              repository_dir = @repository_dir
              expect_recipe do
                chef_mirror "" do
                  chef_repo_path repository_dir
                  versioned_cookbooks false
                  action :download
                end
              end.to have_updated("chef_mirror[]", :download)
              expect(File.read(path_to("cookbooks/x/metadata.rb"))).to eq('name "x"; version "2.0.0"')
            end
          end

          context "and Chef::Config.versioned_cookbooks is true" do
            before do
              Chef::Config.versioned_cookbooks = true
            end

            it "chef_mirror :download downloads all versions of the cookbook" do
              expect_recipe do
                chef_mirror "" do
                  action :download
                end
              end.to have_updated("chef_mirror[]", :download)
              expect(File.read(path_to("cookbooks/x-1.0.0/metadata.rb"))).to eq('name "x"; version "1.0.0"')
              expect(File.read(path_to("cookbooks/x-2.0.0/metadata.rb"))).to eq('name "x"; version "2.0.0"')
            end

            it "chef_mirror :download with versioned_cookbooks = false downloads the latest version of the cookbook" do
              expect_recipe do
                chef_mirror "" do
                  versioned_cookbooks false
                  action :download
                end
              end.to have_updated("chef_mirror[]", :download)
              expect(File.read(path_to("cookbooks/x/metadata.rb"))).to eq('name "x"; version "2.0.0"')
            end

            context "and Chef::Config.chef_repo_path is set elsewhere" do
              before do
                Chef::Config.chef_repo_path = "/x/y/z"
              end

              it "chef_mirror :download with chef_repo_path downloads all versions of the cookbook" do
                repository_dir = @repository_dir
                expect_recipe do
                  chef_mirror "" do
                    chef_repo_path repository_dir
                    action :download
                  end
                end.to have_updated("chef_mirror[]", :download)
                expect(File.read(path_to("cookbooks/x-1.0.0/metadata.rb"))).to eq('name "x"; version "1.0.0"')
                expect(File.read(path_to("cookbooks/x-2.0.0/metadata.rb"))).to eq('name "x"; version "2.0.0"')
              end

              it "chef_mirror :download with chef_repo_path and versioned_cookbooks = false downloads the latest version of the cookbook" do
                repository_dir = @repository_dir
                expect_recipe do
                  chef_mirror "" do
                    chef_repo_path repository_dir
                    versioned_cookbooks false
                    action :download
                  end
                end.to have_updated("chef_mirror[]", :download)
                expect(File.read(path_to("cookbooks/x/metadata.rb"))).to eq('name "x"; version "2.0.0"')
              end
            end
          end
        end
      end
    end
  end
end
