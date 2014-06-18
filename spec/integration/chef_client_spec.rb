require 'support/spec_support'
require 'support/key_support'
require 'chef/resource/chef_client'
require 'chef/provider/chef_client'

repo_path = Dir.mktmpdir('chef_repo')

describe Chef::Resource::ChefClient do
  extend SpecSupport

  when_the_chef_server 'is empty' do
    context 'and we have a private key with a path' do
      with_recipe do
        private_key "#{repo_path}/blah.pem"
      end

      context 'and we run a recipe that creates client "blah"' do
        with_converge do
          chef_client 'blah' do
            source_key_path "#{repo_path}/blah.pem"
          end
        end

        it 'the client gets created' do
          chef_run.should have_updated 'chef_client[blah]', :create
          client = get('/clients/blah')
          client['name'].should == 'blah'
          key, format = Cheffish::KeyFormatter.decode(client['public_key'])
          key.should be_public_key_for("#{repo_path}/blah.pem")
        end
      end

      context 'and we run a recipe that creates client "blah" with output_key_path' do
        with_converge do
          chef_client 'blah' do
            source_key_path "#{repo_path}/blah.pem"
            output_key_path "#{repo_path}/blah.pub"
          end
        end

        it 'the output public key gets created' do
          IO.read("#{repo_path}/blah.pub").should start_with('ssh-rsa ')
          "#{repo_path}/blah.pub".should be_public_key_for("#{repo_path}/blah.pem")
        end
      end
    end

    context "and a private_key 'blah' resource" do
      before :each do
        Chef::Config.private_key_paths = [ repo_path ]
      end

      with_recipe do
        private_key 'blah'
      end

      context "and a chef_client 'foobar' resource with source_key_path 'blah'" do
        with_converge do
          chef_client 'foobar' do
            source_key_path 'blah'
          end
        end

        it 'the client is accessible via the given private key' do
          chef_run.should have_updated 'chef_client[foobar]', :create
          client = get('/clients/foobar')
          key, format = Cheffish::KeyFormatter.decode(client['public_key'])
          key.should be_public_key_for("#{repo_path}/blah.pem")

          private_key = Cheffish::KeyFormatter.decode(Cheffish.get_private_key('blah'))
          key.should be_public_key_for(private_key)
        end
      end
    end
  end
end
