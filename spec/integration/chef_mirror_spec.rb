require 'support/spec_support'
require 'chef/resource/chef_mirror'
require 'chef/provider/chef_mirror'

describe Chef::Resource::ChefMirror do
  extend SpecSupport

  when_the_chef_server 'is in multi-org mode', :osc_compat => false, :single_org => false do
    organization 'foo'

    before :each do
      Chef::Config.chef_server_url = URI.join(Chef::Config.chef_server_url, '/organizations/foo').to_s
    end

    context 'and is empty' do
      when_the_repository 'is full of stuff' do
        file 'nodes/x.json', {}
        file 'roles/x.json', {}

        it "Download grabs defaults" do
          run_recipe do
            chef_mirror '' do
              action :download
            end
          end
          expect(chef_run).to have_updated('chef_mirror[]', :download)
          expect(File.exist?(path_to('groups/admins.json'))).to be true
          expect(File.exist?(path_to('environments/_default.json'))).to be true
        end

        it "Upload uploads everything" do
          run_recipe do
            chef_mirror '' do
              action :upload
            end
          end
          expect(chef_run).to have_updated('chef_mirror[]', :upload)
          expect { get('nodes/x') }.not_to raise_error
          expect { get('roles/x') }.not_to raise_error
        end

        it 'chef_mirror with concurrency 0 fails with a reasonable message' do
          expect {
            run_recipe do
              chef_mirror '' do
                concurrency 0
                action :download
              end
            end
          }.to raise_error /chef_mirror.concurrency must be above 0/
        end
      end

      when_the_repository 'has stuff but no chef_repo_path' do
        file 'repo/nodes/x.json', {}
        file 'repo/roles/x.json', {}
        file 'repo2/nodes/y.json', {}
        file 'repo2/roles/y.json', {}

        before do
          Chef::Config.delete(:chef_repo_path)
          Chef::Config.delete(:node_path)
          Chef::Config.delete(:cookbook_path)
          Chef::Config.delete(:role_path)
        end

        it "Upload with chef_repo_path('repo') uploads everything" do
          repo_path = path_to('repo')
          run_recipe do
            chef_mirror '' do
              chef_repo_path repo_path
              action :upload
            end
          end
          expect(chef_run).to have_updated('chef_mirror[]', :upload)
          expect { get('nodes/x') }.not_to raise_error
          expect { get('roles/x') }.not_to raise_error
          expect { get('nodes/y') }.to raise_error
          expect { get('roles/y') }.to raise_error
        end

        it "Upload with chef_repo_path(:chef_repo_path) with multiple paths uploads everything" do
          repo_path = path_to('repo')
          repo2_path = path_to('repo2')
          run_recipe do
            chef_mirror '' do
              chef_repo_path :chef_repo_path => [ repo_path, repo2_path ]
              action :upload
            end
          end
          expect(chef_run).to have_updated('chef_mirror[]', :upload)
          expect { get('nodes/x') }.not_to raise_error
          expect { get('roles/x') }.not_to raise_error
          expect { get('nodes/y') }.not_to raise_error
          expect { get('roles/y') }.not_to raise_error
        end

        it "Upload with chef_repo_path(:node_path, :role_path) uploads everything" do
          repo_path = path_to('repo')
          repo2_path = path_to('repo2')

          run_recipe do
            chef_mirror '' do
              chef_repo_path :chef_repo_path => '/blahblah',
                             :node_path => "#{repo_path}/nodes",
                             :role_path => "#{repo2_path}/roles"
              action :upload
            end
          end
          expect(chef_run).to have_updated('chef_mirror[]', :upload)
          expect { get('nodes/x') }.not_to raise_error
          expect { get('roles/x') }.to raise_error
          expect { get('nodes/y') }.to raise_error
          expect { get('roles/y') }.not_to raise_error
        end

        it "Upload with chef_repo_path(:chef_repo_path, :role_path) uploads everything" do
          repo_path = path_to('repo')
          repo2_path = path_to('repo2')

          run_recipe do
            chef_mirror '' do
              chef_repo_path :chef_repo_path => repo_path,
                             :role_path => "#{repo2_path}/roles"
              action :upload
            end
          end
          expect(chef_run).to have_updated('chef_mirror[]', :upload)
          expect { get('nodes/x') }.not_to raise_error
          expect { get('roles/x') }.to raise_error
          expect { get('nodes/y') }.to raise_error
          expect { get('roles/y') }.not_to raise_error
        end

        it "Upload with chef_repo_path(:node_path, :role_path) with multiple paths uploads everything" do
          repo_path = path_to('repo')
          repo2_path = path_to('repo2')

          run_recipe do
            chef_mirror '' do
              chef_repo_path :chef_repo_path => [ 'foo', 'bar' ],
                             :node_path => [ "#{repo_path}/nodes", "#{repo2_path}/nodes" ],
                             :role_path => [ "#{repo_path}/roles", "#{repo2_path}/roles" ]
              action :upload
            end
          end
          expect(chef_run).to have_updated('chef_mirror[]', :upload)
          expect { get('nodes/x') }.not_to raise_error
          expect { get('roles/x') }.not_to raise_error
          expect { get('nodes/y') }.not_to raise_error
          expect { get('roles/y') }.not_to raise_error
        end
      end
    end

    context 'and has stuff' do
      node 'x', {}
      role 'x', {}

      when_the_repository 'is empty' do
        it "Download grabs stuff" do
          run_recipe do
            chef_mirror '' do
              action :download
            end
          end
          expect(chef_run).to have_updated('chef_mirror[]', :download)
          expect(File.exist?(path_to('nodes/x.json'))).to be true
          expect(File.exist?(path_to('roles/x.json'))).to be true
        end

        it "Upload uploads nothing" do
          run_recipe do
            chef_mirror '' do
              action :upload
            end
          end
          expect(chef_run).not_to have_updated('chef_mirror[]', :upload)
        end
      end
    end

    context 'and has nodes and roles named x' do
      node 'x', {}
      role 'x', {}

      when_the_repository 'has nodes and roles named y' do
        file 'nodes/y.json', {}
        file 'roles/y.json', {}

        it "Download grabs the x's" do
          run_recipe do
            chef_mirror '' do
              action :download
            end
          end
          expect(chef_run).to have_updated('chef_mirror[]', :download)
          expect(File.exist?(path_to('nodes/x.json'))).to be true
          expect(File.exist?(path_to('roles/x.json'))).to be true
          expect(File.exist?(path_to('nodes/y.json'))).to be true
          expect(File.exist?(path_to('roles/y.json'))).to be true
        end

        it "Upload uploads the y's" do
          run_recipe do
            chef_mirror '' do
              action :upload
            end
          end
          expect(chef_run).to have_updated('chef_mirror[]', :upload)
          expect { get('nodes/x') }.not_to raise_error
          expect { get('roles/x') }.not_to raise_error
          expect { get('nodes/y') }.not_to raise_error
          expect { get('roles/y') }.not_to raise_error
        end

        it "Download with purge grabs the x's and deletes the y's" do
          run_recipe do
            chef_mirror '' do
              purge true
              action :download
            end
          end
          expect(chef_run).to have_updated('chef_mirror[]', :download)
          expect(File.exist?(path_to('nodes/x.json'))).to be true
          expect(File.exist?(path_to('roles/x.json'))).to be true
        end

        it "Upload with :purge uploads the y's and deletes the x's" do
          run_recipe do
            chef_mirror '*/*.json' do
              purge true
              action :upload
            end
          end
          expect(chef_run).to have_updated('chef_mirror[*/*.json]', :upload)
          expect { get('nodes/y') }.not_to raise_error
          expect { get('roles/y') }.not_to raise_error
        end
      end
    end

  end
end
