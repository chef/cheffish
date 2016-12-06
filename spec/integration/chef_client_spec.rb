require "support/spec_support"
require "cheffish/rspec/chef_run_support"
require "support/key_support"
require "chef/resource/chef_client"

repo_path = Dir.mktmpdir("chef_repo")

describe Chef::Resource::ChefClient do
  extend Cheffish::RSpec::ChefRunSupport

  when_the_chef_12_server "is in multi-org mode" do
    organization "foo"

    before :each do
      Chef::Config.chef_server_url = URI.join(Chef::Config.chef_server_url, "/organizations/foo").to_s
    end

    context "and is empty" do
      context "and we have a private key with a path" do
        with_converge do
          private_key "#{repo_path}/blah.pem"
        end

        context 'and we run a recipe that creates client "blah"' do
          it "the client gets created" do
            expect_recipe do
              chef_client "blah" do
                source_key_path "#{repo_path}/blah.pem"
              end
            end.to have_updated "chef_client[blah]", :create
            client = get("clients/blah")
            expect(client["name"]).to eq("blah")
            key, format = Cheffish::KeyFormatter.decode(client["public_key"])
            expect(key).to be_public_key_for("#{repo_path}/blah.pem")
          end
        end

        context 'and we run a recipe that creates client "blah" with output_key_path' do
          with_converge do
            chef_client "blah" do
              source_key_path "#{repo_path}/blah.pem"
              output_key_path "#{repo_path}/blah.pub"
            end
          end

          it "the output public key gets created" do
            expect(IO.read("#{repo_path}/blah.pub")).to start_with("ssh-rsa ")
            expect("#{repo_path}/blah.pub").to be_public_key_for("#{repo_path}/blah.pem")
          end
        end
      end

      context "and a private_key 'blah' resource" do
        before :each do
          Chef::Config.private_key_paths = [ repo_path ]
        end

        with_converge do
          private_key "blah"
        end

        context "and a chef_client 'foobar' resource with source_key_path 'blah'" do
          it "the client is accessible via the given private key" do
            expect_recipe do
              chef_client "foobar" do
                source_key_path "blah"
              end
            end.to have_updated "chef_client[foobar]", :create
            client = get("clients/foobar")
            key, format = Cheffish::KeyFormatter.decode(client["public_key"])
            expect(key).to be_public_key_for("#{repo_path}/blah.pem")

            private_key = Cheffish::KeyFormatter.decode(Cheffish.get_private_key("blah"))
            expect(key).to be_public_key_for(private_key)
          end
        end
      end
    end
  end

  when_the_chef_server "is in OSC mode" do
    context "and is empty" do
      context "and we have a private key with a path" do
        with_converge do
          private_key "#{repo_path}/blah.pem"
        end

        context 'and we run a recipe that creates client "blah"' do
          it "the client gets created" do
            expect_recipe do
              chef_client "blah" do
                source_key_path "#{repo_path}/blah.pem"
              end
            end.to have_updated "chef_client[blah]", :create
            client = get("clients/blah")
            expect(client["name"]).to eq("blah")
            key, format = Cheffish::KeyFormatter.decode(client["public_key"])
            expect(key).to be_public_key_for("#{repo_path}/blah.pem")
          end
        end
      end
    end
  end
end
