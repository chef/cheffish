require "support/spec_support"
require "cheffish/rspec/chef_run_support"

describe Chef::Resource::ChefRole do
  extend Cheffish::RSpec::ChefRunSupport

  when_the_chef_12_server "is in multi-org mode" do
    organization "foo"

    before :each do
      Chef::Config.chef_server_url = URI.join(Chef::Config.chef_server_url, "/organizations/foo").to_s
    end

    context "and is empty" do
      context 'and we run a recipe that creates role "blah"' do
        it "the role gets created" do
          expect_recipe do
            chef_role "blah"
          end.to have_updated "chef_role[blah]", :create
          expect(get("roles/blah")["name"]).to eq("blah")
        end
      end

      # TODO why-run mode

      context "and another chef server is running on port 8899" do
        before :each do
          @server = ChefZero::Server.new(:port => 8899)
          @server.start_background
        end

        after :each do
          @server.stop
        end

        context 'and a recipe is run that creates role "blah" on the second chef server using with_chef_server' do

          it "the role is created on the second chef server but not the first" do
            expect_recipe do
              with_chef_server "http://127.0.0.1:8899"
              chef_role "blah"
            end.to have_updated "chef_role[blah]", :create
            expect { get("roles/blah") }.to raise_error(Net::HTTPServerException)
            expect(get("http://127.0.0.1:8899/roles/blah")["name"]).to eq("blah")
          end
        end

        context 'and a recipe is run that creates role "blah" on the second chef server using chef_server' do

          it "the role is created on the second chef server but not the first" do
            expect_recipe do
              chef_role "blah" do
                chef_server({ :chef_server_url => "http://127.0.0.1:8899" })
              end
            end.to have_updated "chef_role[blah]", :create
            expect { get("roles/blah") }.to raise_error(Net::HTTPServerException)
            expect(get("http://127.0.0.1:8899/roles/blah")["name"]).to eq("blah")
          end
        end
      end
    end
  end

  when_the_chef_server "is in OSC mode" do
    context "and is empty" do
      context 'and we run a recipe that creates role "blah"' do
        it "the role gets created" do
          expect_recipe do
            chef_role "blah"
          end.to have_updated "chef_role[blah]", :create
          expect(get("roles/blah")["name"]).to eq("blah")
        end
      end
    end
  end
end
