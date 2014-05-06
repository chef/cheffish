require 'support/spec_support'
require 'support/key_support'
require 'chef/resource/chef_client'
require 'chef/provider/chef_client'

repo_path = Dir.mktmpdir('chef_repo')

describe Chef::Resource::ChefClient do
  extend SpecSupport

  when_the_chef_server 'is empty' do
    context 'and we have a private key' do
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
  end
end
