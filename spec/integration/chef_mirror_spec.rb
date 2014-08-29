require 'support/spec_support'
require 'chef/resource/chef_mirror'
require 'chef/provider/chef_mirror'

describe Chef::Resource::ChefMirror, :focus do
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
