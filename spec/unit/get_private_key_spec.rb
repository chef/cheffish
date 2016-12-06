require "support/spec_support"
require "cheffish/rspec/chef_run_support"

describe Cheffish do
  let(:directory_that_exists) do
    Dir.mktmpdir("cheffish-rspec")
  end

  let(:directory_that_does_not_exist) do
    dir = Dir.mktmpdir("cheffish-rspec")
    FileUtils.remove_entry dir
    dir
  end

  let(:private_key_contents) { "contents of private key" }

  let(:private_key_pem_contents) { "contents of private key pem" }

  let(:private_key_garbage_contents) { "da vinci virus" }

  def setup_key
    key_file = File.expand_path("ned_stark", directory_that_exists)
    File.open(key_file, "w+") do |f|
      f.write private_key_contents
    end
    key_file
  end

  def setup_arbitrarily_named_key
    key_file = File.expand_path("ned_stark.xxx", directory_that_exists)
    File.open(key_file, "w+") do |f|
      f.write private_key_contents
    end
    key_file
  end

  def setup_pem_key
    key_file = File.expand_path("ned_stark.pem", directory_that_exists)
    File.open(key_file, "w+") do |f|
      f.write private_key_pem_contents
    end
    key_file
  end

  def setup_garbage_key
    key_file = File.expand_path("ned_stark.pem.bak", directory_that_exists)
    File.open(key_file, "w+") do |f|
      f.write private_key_garbage_contents
    end
    key_file
  end

  shared_examples_for "returning the contents of the key file if it finds one" do
    it "returns nil if it cannot find the private key file" do
      expect(Cheffish.get_private_key("ned_stark", config)).to be_nil
    end

    it "returns the contents of the key if it doesn't have an extension" do
      setup_key
      expect(Cheffish.get_private_key("ned_stark", config)).to eq(private_key_contents)
    end

    it "returns the contents of the key if it has an extension" do
      setup_pem_key
      expect(Cheffish.get_private_key("ned_stark", config)).to eq(private_key_pem_contents)
    end

    it "returns the contents of arbitrarily named keys" do
      setup_arbitrarily_named_key
      expect(Cheffish.get_private_key("ned_stark.xxx", config)).to eq(private_key_contents)
    end

    # we arbitrarily prefer "ned_stark" over "ned_stark.pem" for deterministic behavior
    it "returns the contents of the key that does not have an extension if both exist" do
      setup_key
      setup_pem_key
      expect(Cheffish.get_private_key("ned_stark", config)).to eq(private_key_contents)
    end
  end

  describe "#get_private_key" do
    context "when private_key_paths has a directory which is empty" do
      let(:config) do
        { :private_key_paths => [ directory_that_exists ] }
      end

      it_behaves_like "returning the contents of the key file if it finds one"

      context "when it also has a garbage file" do
        before { setup_garbage_key }

        it "does not return the da vinci virus if we find only the garbage file" do
          setup_garbage_key
          expect(Cheffish.get_private_key("ned_stark", config)).to be_nil
        end

        it_behaves_like "returning the contents of the key file if it finds one"
      end

    end

    context "when private_key_paths leads with a directory that does not exist and then an empty directory" do
      let(:config) do
        { :private_key_paths => [ directory_that_does_not_exist, directory_that_exists ] }
      end

      it_behaves_like "returning the contents of the key file if it finds one"
    end

    context "when private_keys is empty" do
      let(:config) do
        { :private_keys => {} }
      end

      it "returns nil" do
        expect(Cheffish.get_private_key("ned_stark", config)).to be_nil
      end
    end

    context "when private_keys contains the path to a key" do
      let(:name) { "ned_stark" }
      let(:config) do
        { :private_keys => { name => setup_key } }
      end

      it "returns the contents of the key file" do
        setup_key
        expect(Cheffish.get_private_key(name, config)).to eq(private_key_contents)
      end
    end

    context "when private_keys contains the path to a key" do
      let(:name) { "ned_stark" }
      let(:key) { double("key", :to_pem => private_key_contents) }
      let(:config) do
        { :private_keys => { name => key } }
      end

      it "returns the contents of the key file" do
        expect(Cheffish.get_private_key(name, config)).to eq(private_key_contents)
      end
    end
  end
end
