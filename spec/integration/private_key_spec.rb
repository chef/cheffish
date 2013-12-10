require 'support/spec_support'
require 'cheffish/resource/private_key'
require 'cheffish/provider/private_key'
require 'cheffish/resource/public_key'
require 'cheffish/provider/public_key'
require 'support/key_support'

repo_path = Dir.mktmpdir('chef_repo')

describe Cheffish::Resource::PrivateKey do
  extend SpecSupport

  before :each do
    FileUtils.remove_entry_secure(repo_path)
    Dir.mkdir(repo_path)
  end

  context 'with a recipe with a private_key' do
    with_recipe do
      private_key "#{repo_path}/blah"
    end

    it 'the private_key is created in pem format' do
      chef_run.should have_updated "private_key[#{repo_path}/blah]", :create
      IO.read("#{repo_path}/blah").should start_with('-----BEGIN')
      OpenSSL::PKey.read(IO.read("#{repo_path}/blah")).kind_of?(OpenSSL::PKey::RSA).should be_true
    end

    context 'and a public_key' do
      with_recipe do
        public_key "#{repo_path}/blah.pub" do
          source "#{repo_path}/blah"
        end
      end

      it 'the public_key is created' do
        chef_run.should have_updated "private_key[#{repo_path}/blah]", :create
        chef_run.should have_updated "public_key[#{repo_path}/blah.pub]", :create
        IO.read("#{repo_path}/blah.pub").should start_with('ssh-rsa ')
        "#{repo_path}/blah.pub".should be_public_key_for "#{repo_path}/blah"
      end

      context 'and another public_key based off the first public_key' do
        with_recipe do
          public_key "#{repo_path}/blah.pub2" do
            source "#{repo_path}/blah.pub"
          end
        end

        it 'the second public_key is created' do
          chef_run.should have_updated "public_key[#{repo_path}/blah.pub2]", :create
          IO.read("#{repo_path}/blah.pub").should start_with('ssh-rsa ')
          "#{repo_path}/blah.pub".should be_public_key_for "#{repo_path}/blah"
        end
      end

      context 'and another public_key in :pem format based off the first public_key' do
        with_recipe do
          public_key "#{repo_path}/blah.pub2" do
            source "#{repo_path}/blah.pub"
            format :pem
          end
        end

        it 'the second public_key is created' do
          chef_run.should have_updated "public_key[#{repo_path}/blah.pub2]", :create
          IO.read("#{repo_path}/blah.pub").should start_with('ssh-rsa ')
          "#{repo_path}/blah.pub".should be_public_key_for "#{repo_path}/blah"
        end
      end

      context 'and another public_key in :der format based off the first public_key' do
        with_recipe do
          public_key "#{repo_path}/blah.pub2" do
            source "#{repo_path}/blah.pub"
            format :pem
          end
        end

        it 'the second public_key is created' do
          chef_run.should have_updated "public_key[#{repo_path}/blah.pub2]", :create
          IO.read("#{repo_path}/blah.pub").should start_with('ssh-rsa ')
          "#{repo_path}/blah.pub".should be_public_key_for "#{repo_path}/blah"
        end
      end
    end

    context 'and a public key in pem format' do
      with_recipe do
        public_key "#{repo_path}/blah.pub" do
          source "#{repo_path}/blah"
          format :pem
        end
      end

      it 'the public_key is created' do
        chef_run.should have_updated "private_key[#{repo_path}/blah]", :create
        chef_run.should have_updated "public_key[#{repo_path}/blah.pub]", :create
        IO.read("#{repo_path}/blah.pub").should start_with('-----BEGIN')
        "#{repo_path}/blah.pub".should be_public_key_for "#{repo_path}/blah"
      end
    end

    context 'and a public key in der format' do
      with_recipe do
        public_key "#{repo_path}/blah.pub" do
          source "#{repo_path}/blah"
          format :der
        end
      end

      it 'the public_key is created in openssh format' do
        chef_run.should have_updated "private_key[#{repo_path}/blah]", :create
        chef_run.should have_updated "public_key[#{repo_path}/blah.pub]", :create
        IO.read("#{repo_path}/blah.pub").should_not start_with('-----BEGIN')
        IO.read("#{repo_path}/blah.pub").should_not start_with('ssh-rsa')
        "#{repo_path}/blah.pub".should be_public_key_for "#{repo_path}/blah"
      end
    end
  end

  context 'with a recipe with a private_key in der format' do
    with_recipe do
      private_key "#{repo_path}/blah" do
        format :der
      end
    end

    it 'the private_key is created' do
      chef_run.should have_updated "private_key[#{repo_path}/blah]", :create
      IO.read("#{repo_path}/blah").should_not start_with('-----BEGIN')
      OpenSSL::PKey.read(IO.read("#{repo_path}/blah")).kind_of?(OpenSSL::PKey::RSA).should be_true
    end

    context 'and a public_key' do
      with_recipe do
        public_key "#{repo_path}/blah.pub" do
          source "#{repo_path}/blah"
        end
      end

      it 'the public_key is created in openssh format' do
        chef_run.should have_updated "private_key[#{repo_path}/blah]", :create
        chef_run.should have_updated "public_key[#{repo_path}/blah.pub]", :create
        IO.read("#{repo_path}/blah.pub").should start_with('ssh-rsa ')
        "#{repo_path}/blah.pub".should be_public_key_for "#{repo_path}/blah"
      end
    end
  end

  context 'with a recipe with a private_key with a pass_phrase' do
    with_recipe do
      private_key "#{repo_path}/blah" do
        pass_phrase 'hello'
      end
    end

    it 'the private_key is created' do
      chef_run.should have_updated "private_key[#{repo_path}/blah]", :create
      IO.read("#{repo_path}/blah").should start_with('-----BEGIN')
      OpenSSL::PKey.read(IO.read("#{repo_path}/blah"), 'hello').kind_of?(OpenSSL::PKey::RSA).should be_true
    end

    context 'and a public_key' do
      with_recipe do
        public_key "#{repo_path}/blah.pub" do
          source "#{repo_path}/blah"
          source_pass_phrase 'hello'
        end
      end

      it 'the public_key is created in openssh format' do
        chef_run.should have_updated "private_key[#{repo_path}/blah]", :create
        chef_run.should have_updated "public_key[#{repo_path}/blah.pub]", :create
        IO.read("#{repo_path}/blah.pub").should start_with('ssh-rsa ')
        "#{repo_path}/blah.pub".should be_public_key_for "#{repo_path}/blah", 'hello'
      end
    end
  end
end

