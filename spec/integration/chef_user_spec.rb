require 'support/spec_support'
require 'support/key_support'
require 'chef/resource/chef_user'
require 'chef/provider/chef_user'

repo_path = Dir.mktmpdir('chef_repo')

describe Chef::Resource::ChefUser do
  extend SpecSupport

  when_the_chef_server 'is empty' do
    context 'and we have a private key' do
      with_recipe do
        private_key "#{repo_path}/blah.pem"
      end

      context 'and we run a recipe that creates user "blah"'do
        with_converge do
          chef_user 'blah' do
            source_key_path "#{repo_path}/blah.pem"
          end
        end

        it 'the user gets created' do
          expect(chef_run).to have_updated 'chef_user[blah]', :create
          user = get('/users/blah')
          expect(user['name']).to eq('blah')
          key, format = Cheffish::KeyFormatter.decode(user['public_key'])
          expect(key).to be_public_key_for("#{repo_path}/blah.pem")
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
          expect(IO.read("#{repo_path}/blah.pub")).to start_with('ssh-rsa ')
          expect("#{repo_path}/blah.pub").to be_public_key_for("#{repo_path}/blah.pem")
        end
      end
    end
  end
end
