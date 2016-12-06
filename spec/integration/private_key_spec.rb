require "support/spec_support"
require "cheffish/rspec/chef_run_support"
require "support/key_support"

repo_path = Dir.mktmpdir("chef_repo")

describe Chef::Resource::PrivateKey do
  extend Cheffish::RSpec::ChefRunSupport

  before :each do
    FileUtils.remove_entry_secure(repo_path)
    Dir.mkdir(repo_path)
  end

  context "with a recipe with a private_key" do
    it "the private_key is created in pem format" do
      expect_recipe do
        private_key "#{repo_path}/blah"
      end.to have_updated "private_key[#{repo_path}/blah]", :create
      expect(IO.read("#{repo_path}/blah")).to start_with("-----BEGIN")
      expect(OpenSSL::PKey.read(IO.read("#{repo_path}/blah"))).to be_kind_of(OpenSSL::PKey::RSA)
    end
  end

  context 'with a private_key "blah" resource' do
    before :each do
      Dir.mkdir("#{repo_path}/other_keys")
      Chef::Config.private_key_paths = [ repo_path, "#{repo_path}/other_keys" ]
    end

    it "the private key is created in the private_key_write_path" do
      expect_recipe do
        private_key "blah"
      end.to have_updated "private_key[blah]", :create
      expect(Chef::Config.private_key_write_path).to eq(repo_path)
      expect(File.exist?("#{repo_path}/blah")).to be true
      expect(File.exist?("#{repo_path}/other_keys/blah")).to be false
      expect(OpenSSL::PKey.read(IO.read("#{repo_path}/blah"))).to be_kind_of(OpenSSL::PKey::RSA)
      expect(OpenSSL::PKey.read(Cheffish.get_private_key("blah"))).to be_kind_of(OpenSSL::PKey::RSA)
    end

    context "and the private key already exists somewhere not in the write path" do
      before :each do
        recipe { private_key "#{repo_path}/other_keys/blah" }.converge
      end

      it "the private expect(key).to not update" do
        expect_recipe do
          private_key "blah"
        end.not_to have_updated "private_key[blah]", :create

        expect(File.exist?("#{repo_path}/blah")).to be false
        expect(File.exist?("#{repo_path}/other_keys/blah")).to be true
      end
    end
  end

  context "with a private key" do
    before :each do
      Cheffish::BasicChefClient.converge_block do
        private_key "#{repo_path}/blah"
      end
    end

    context "and a private_key that copies it in der format" do
      it "the private_key is copied in der format and is identical" do
        expect_recipe do
          private_key "#{repo_path}/blah.der" do
            source_key_path "#{repo_path}/blah"
            format :der
          end
        end.to have_updated "private_key[#{repo_path}/blah.der]", :create
        key_str = IO.read("#{repo_path}/blah.der")
        expect(key_str).not_to start_with("-----BEGIN")
        expect(key_str).not_to start_with("ssh-")
        expect("#{repo_path}/blah.der").to match_private_key("#{repo_path}/blah")
      end
    end

    it "a private_key that copies it from in-memory as a string succeeds" do
      expect_recipe do
        private_key "#{repo_path}/blah.der" do
          source_key IO.read("#{repo_path}/blah")
          format :der
        end
      end.to have_updated "private_key[#{repo_path}/blah.der]", :create
      key_str = IO.read("#{repo_path}/blah.der")
      expect(key_str).not_to start_with("-----BEGIN")
      expect(key_str).not_to start_with("ssh-")
      expect("#{repo_path}/blah.der").to match_private_key("#{repo_path}/blah")
    end

    it "a private_key that copies it from in-memory as a key succeeds" do
      key = OpenSSL::PKey.read(IO.read("#{repo_path}/blah"))
      expect_recipe do
        private_key "#{repo_path}/blah.der" do
          source_key key
          format :der
        end
      end.to have_updated "private_key[#{repo_path}/blah.der]", :create
      key_str = IO.read("#{repo_path}/blah.der")
      expect(key_str).not_to start_with("-----BEGIN")
      expect(key_str).not_to start_with("ssh-")
      expect("#{repo_path}/blah.der").to match_private_key("#{repo_path}/blah")
    end

    context "and a public_key recipe" do
      it "the public_key is created" do
        expect_recipe do
          public_key "#{repo_path}/blah.pub" do
            source_key_path "#{repo_path}/blah"
          end
        end.to have_updated "public_key[#{repo_path}/blah.pub]", :create
        expect(IO.read("#{repo_path}/blah.pub")).to start_with("ssh-rsa ")
        expect("#{repo_path}/blah.pub").to be_public_key_for "#{repo_path}/blah"
      end
    end

    context "and a public key" do
      before :each do
        Cheffish::BasicChefClient.converge_block do
          public_key "#{repo_path}/blah.pub" do
            source_key_path "#{repo_path}/blah"
          end
        end
      end

      context "and public_key resource based off the public key file" do
        it "the second public_key is created" do
          expect_recipe do
            public_key "#{repo_path}/blah.pub2" do
              source_key_path "#{repo_path}/blah.pub"
            end
          end.to have_updated "public_key[#{repo_path}/blah.pub2]", :create
          expect(IO.read("#{repo_path}/blah.pub")).to start_with("ssh-rsa ")
          expect("#{repo_path}/blah.pub").to be_public_key_for "#{repo_path}/blah"
        end
      end

      context "and another public_key based off the first public_key in-memory in a string" do
        it "the second public_key is created" do
          expect_recipe do
            public_key "#{repo_path}/blah.pub2" do
              source_key IO.read("#{repo_path}/blah.pub")
            end
          end.to have_updated "public_key[#{repo_path}/blah.pub2]", :create
          expect(IO.read("#{repo_path}/blah.pub")).to start_with("ssh-rsa ")
          expect("#{repo_path}/blah.pub").to be_public_key_for "#{repo_path}/blah"
        end
      end

      it "and another public_key based off the first public_key in-memory in a key, the second public_key is created" do
        key, format = Cheffish::KeyFormatter.decode(IO.read("#{repo_path}/blah.pub"))

        expect_recipe do
          public_key "#{repo_path}/blah.pub2" do
            source_key key
          end
        end.to have_updated "public_key[#{repo_path}/blah.pub2]", :create
        expect(IO.read("#{repo_path}/blah.pub")).to start_with("ssh-rsa ")
        expect("#{repo_path}/blah.pub").to be_public_key_for "#{repo_path}/blah"
      end

      context "and another public_key in :pem format based off the first public_key" do
        it "the second public_key is created" do
          expect_recipe do
            public_key "#{repo_path}/blah.pub2" do
              source_key_path "#{repo_path}/blah.pub"
              format :pem
            end
          end.to have_updated "public_key[#{repo_path}/blah.pub2]", :create
          expect(IO.read("#{repo_path}/blah.pub")).to start_with("ssh-rsa ")
          expect("#{repo_path}/blah.pub").to be_public_key_for "#{repo_path}/blah"
        end
      end

      context "and another public_key in :der format based off the first public_key" do
        it "the second public_key is created" do
          expect_recipe do
            public_key "#{repo_path}/blah.pub2" do
              source_key_path "#{repo_path}/blah.pub"
              format :pem
            end
          end.to have_updated "public_key[#{repo_path}/blah.pub2]", :create
          expect(IO.read("#{repo_path}/blah.pub")).to start_with("ssh-rsa ")
          expect("#{repo_path}/blah.pub").to be_public_key_for "#{repo_path}/blah"
        end
      end
    end

    context "and a public_key resource in pem format" do
      it "the public_key is created" do
        expect_recipe do
          public_key "#{repo_path}/blah.pub" do
            source_key_path "#{repo_path}/blah"
            format :pem
          end
        end.to have_updated "public_key[#{repo_path}/blah.pub]", :create
        expect(IO.read("#{repo_path}/blah.pub")).to start_with("-----BEGIN")
        expect("#{repo_path}/blah.pub").to be_public_key_for "#{repo_path}/blah"
      end
    end

    context "and a public_key resource in der format" do
      it "the public_key is created in openssh format" do
        expect_recipe do
          public_key "#{repo_path}/blah.pub" do
            source_key_path "#{repo_path}/blah"
            format :der
          end
        end.to have_updated "public_key[#{repo_path}/blah.pub]", :create
        expect(IO.read("#{repo_path}/blah.pub")).not_to start_with("-----BEGIN")
        expect(IO.read("#{repo_path}/blah.pub")).not_to start_with("ssh-rsa")
        expect("#{repo_path}/blah.pub").to be_public_key_for "#{repo_path}/blah"
      end
    end
  end

  context "with a recipe with a private_key in der format" do
    it "the private_key is created" do
      expect_recipe do
        private_key "#{repo_path}/blah" do
          format :der
        end
      end.to have_updated "private_key[#{repo_path}/blah]", :create
      expect(IO.read("#{repo_path}/blah")).not_to start_with("-----BEGIN")
      expect(OpenSSL::PKey.read(IO.read("#{repo_path}/blah"))).to be_kind_of(OpenSSL::PKey::RSA)
    end
  end

  context "with a private key in der format" do
    before :each do
      Cheffish::BasicChefClient.converge_block do
        private_key "#{repo_path}/blah" do
          format :der
        end
      end
    end

    context "and a public_key" do
      it "the public_key is created in openssh format" do
        expect_recipe do
          public_key "#{repo_path}/blah.pub" do
            source_key_path "#{repo_path}/blah"
          end
        end.to have_updated "public_key[#{repo_path}/blah.pub]", :create
        expect(IO.read("#{repo_path}/blah.pub")).to start_with("ssh-rsa ")
        expect("#{repo_path}/blah.pub").to be_public_key_for "#{repo_path}/blah"
      end
    end
  end

  context "with a recipe with a private_key with a pass_phrase" do
    it "the private_key is created" do
      expect_recipe do
        private_key "#{repo_path}/blah" do
          pass_phrase "hello"
        end
      end.to have_updated "private_key[#{repo_path}/blah]", :create
      expect(IO.read("#{repo_path}/blah")).to start_with("-----BEGIN")
      expect(OpenSSL::PKey.read(IO.read("#{repo_path}/blah"), "hello")).to be_kind_of(OpenSSL::PKey::RSA)
    end
  end

  context "with a private key with a pass phrase" do
    before :each do
      Cheffish::BasicChefClient.converge_block do
        private_key "#{repo_path}/blah" do
          pass_phrase "hello"
        end
      end
    end

    context "and a private_key that copies it in der format" do
      it "the private_key is copied in der format and is identical" do
        expect_recipe do
          private_key "#{repo_path}/blah.der" do
            source_key_path "#{repo_path}/blah"
            source_key_pass_phrase "hello"
            format :der
          end
        end.to have_updated "private_key[#{repo_path}/blah.der]", :create
        key_str = IO.read("#{repo_path}/blah.der")
        expect(key_str).not_to start_with("-----BEGIN")
        expect(key_str).not_to start_with("ssh-")
        expect("#{repo_path}/blah.der").to match_private_key("#{repo_path}/blah", "hello")
      end
    end

    context "and a private_key resource pointing at it without a pass_phrase" do
      it "the run fails with an exception" do
        expect do
          converge do
            private_key "#{repo_path}/blah"
          end
        end.to raise_error /missing pass phrase?/
      end
    end

    context "and a private_key resource with no pass phrase and regenerate_if_different" do
      it "the private_key is regenerated" do
        expect_recipe do
          private_key "#{repo_path}/blah" do
            regenerate_if_different true
          end
        end.to have_updated "private_key[#{repo_path}/blah]", :create
        expect(IO.read("#{repo_path}/blah")).to start_with("-----BEGIN")
        expect(OpenSSL::PKey.read(IO.read("#{repo_path}/blah"))).to be_kind_of(OpenSSL::PKey::RSA)
      end
    end

    it "a private_key resource that copies it from in-memory as a string succeeds" do
      expect_recipe do
        private_key "#{repo_path}/blah.der" do
          source_key IO.read("#{repo_path}/blah")
          source_key_pass_phrase "hello"
          format :der
        end
      end.to have_updated "private_key[#{repo_path}/blah.der]", :create
      key_str = IO.read("#{repo_path}/blah.der")
      expect(key_str).not_to start_with("-----BEGIN")
      expect(key_str).not_to start_with("ssh-")
      expect("#{repo_path}/blah.der").to match_private_key("#{repo_path}/blah", "hello")
    end

    context "and a public_key" do
      it "the public_key is created in openssh format" do
        expect_recipe do
          public_key "#{repo_path}/blah.pub" do
            source_key_path "#{repo_path}/blah"
            source_key_pass_phrase "hello"
          end
        end.to have_updated "public_key[#{repo_path}/blah.pub]", :create
        expect(IO.read("#{repo_path}/blah.pub")).to start_with("ssh-rsa ")
        expect("#{repo_path}/blah.pub").to be_public_key_for "#{repo_path}/blah", "hello"
      end
    end

    context "and a public_key derived from the private key in an in-memory string" do
      it "the public_key is created in openssh format" do
        expect_recipe do
          public_key "#{repo_path}/blah.pub" do
            source_key IO.read("#{repo_path}/blah")
            source_key_pass_phrase "hello"
          end
        end.to have_updated "public_key[#{repo_path}/blah.pub]", :create
        expect(IO.read("#{repo_path}/blah.pub")).to start_with("ssh-rsa ")
        expect("#{repo_path}/blah.pub").to be_public_key_for "#{repo_path}/blah", "hello"
      end
    end
  end

  context "with a recipe with a private_key and public_key_path" do
    it "the private_key and public_key are created" do
      expect_recipe do
        private_key "#{repo_path}/blah" do
          public_key_path "#{repo_path}/blah.pub"
        end
      end.to have_updated "private_key[#{repo_path}/blah]", :create
      expect(IO.read("#{repo_path}/blah")).to start_with("-----BEGIN")
      expect(OpenSSL::PKey.read(IO.read("#{repo_path}/blah"))).to be_kind_of(OpenSSL::PKey::RSA)
      expect(IO.read("#{repo_path}/blah.pub")).to start_with("ssh-rsa ")
      expect("#{repo_path}/blah.pub").to be_public_key_for("#{repo_path}/blah")
    end
  end

  context "with a recipe with a private_key and public_key_path and public_key_format" do
    it "the private_key and public_key are created" do
      expect_recipe do
        private_key "#{repo_path}/blah" do
          public_key_path "#{repo_path}/blah.pub.der"
          public_key_format :der
        end
      end.to have_updated "private_key[#{repo_path}/blah]", :create
      expect(IO.read("#{repo_path}/blah")).to start_with("-----BEGIN")
      expect(OpenSSL::PKey.read(IO.read("#{repo_path}/blah"))).to be_kind_of(OpenSSL::PKey::RSA)
      expect(IO.read("#{repo_path}/blah.pub.der")).not_to start_with("ssh-rsa ")
      expect("#{repo_path}/blah.pub.der").to be_public_key_for("#{repo_path}/blah")
    end
  end

  context "with a recipe with a private_key with path :none" do
    it "the private_key is created" do
      got_private_key = nil
      expect_recipe do
        private_key "in_memory" do
          path :none
          after { |resource, private_key| got_private_key = private_key }
        end
      end.to have_updated "private_key[in_memory]", :create
      expect(got_private_key).to be_kind_of(OpenSSL::PKey::RSA)
    end
  end

end
