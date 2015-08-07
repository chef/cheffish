require 'support/spec_support'
require 'cheffish/rspec/chef_run_support'

describe 'Cheffish::RSpec::ChefRunSupport' do
  extend Cheffish::RSpec::ChefRunSupport

  let(:tempfile) { Tempfile.new('test') }

  context "#recipe" do
    it "recipe { file ... } updates the file" do
      result = recipe {
        file tempfile.path do
          content 'test'
        end
      }
      expect(result.updated?).to be_falsey
      expect(IO.read(tempfile.path)).to eq ''
    end

    it "recipe 'file ...' does not update the file" do
      result = recipe <<-EOM
        file tempfile.path do
          content 'test'
        end
      EOM
      expect(result.updated?).to be_falsey
      expect(IO.read(tempfile.path)).to eq ''
    end

    it "recipe 'file ...' with file and line number does not update the file" do
      result = recipe(<<-EOM, __FILE__, __LINE__+1)
        file tempfile.path do
          content 'test'
        end
      EOM
      expect(result.updated?).to be_falsey
      expect(IO.read(tempfile.path)).to eq ''
    end
  end

  context "#converge" do
    it "converge { file ... } updates the file" do
      result = converge {
        file tempfile.path do
          content 'test'
        end
      }
      expect(result.updated?).to be_truthy
      expect(IO.read(tempfile.path)).to eq 'test'
    end

    it "converge 'file ...' updates the file" do
      result = converge <<-EOM
        file tempfile.path do
          content 'test'
        end
      EOM
      expect(result.updated?).to be_truthy
      expect(IO.read(tempfile.path)).to eq 'test'
    end

    it "converge 'file ...' with file and line number updates the file" do
      result = converge(<<-EOM, __FILE__, __LINE__+1)
        file tempfile.path do
          content 'test'
        end
      EOM
      expect(result.updated?).to be_truthy
      expect(IO.read(tempfile.path)).to eq 'test'
    end
  end

  context "#expect_recipe" do
    it "expect_recipe { file ... }.to be_updated updates the file, and be_idempotent does not fail" do
      expect_recipe {
        file tempfile.path do
          content 'test'
        end
      }.to be_updated.and be_idempotent

      expect(IO.read(tempfile.path)).to eq 'test'
    end

    it "expect_recipe 'file ...'.to be_updated updates the file, and be_idempotent does not fail" do
      expect_recipe(<<-EOM).to be_updated.and be_idempotent
        file tempfile.path do
          content 'test'
        end
      EOM

      expect(IO.read(tempfile.path)).to eq 'test'
    end

    it "expect_recipe('file ...', file, line).to be_updated updates the file, and be_idempotent does not fail" do
      expect_recipe(<<-EOM, __FILE__, __LINE__+1).to be_updated.and be_idempotent
        file tempfile.path do
          content 'test'
        end
      EOM

      expect(IO.read(tempfile.path)).to eq 'test'
    end

    it "expect_recipe { file ... }.to be_up_to_date fails" do
      expect {
        expect_recipe {
          file tempfile.path do
            content 'test'
          end
        }.to be_up_to_date
      }.to raise_error
    end

    it "expect_recipe { }.to be_updated fails" do
      expect {
        expect_recipe { }.to be_updated
      }.to raise_error
    end

    it "expect_recipe { }.to be_up_to_date succeeds" do
      expect_recipe { }.to be_up_to_date
    end

    it "expect_recipe { }.to be_idempotent succeeds" do
      expect_recipe { }.to be_idempotent
    end
  end

  context "#expect_converge" do
    it "expect_converge { file ... }.not_to raise_error updates the file" do
      expect_converge {
        file tempfile.path do
          content 'test'
        end
      }.not_to raise_error
      expect(IO.read(tempfile.path)).to eq 'test'
    end

    it "expect_converge('file ...').not_to raise_error updates the file" do
      expect_converge(<<-EOM).not_to raise_error
        file tempfile.path do
          content 'test'
        end
      EOM
      expect(IO.read(tempfile.path)).to eq 'test'
    end

    it "expect_converge('file ...', file, line).not_to raise_error updates the file" do
      expect_converge(<<-EOM, __FILE__, __LINE__+1).not_to raise_error
        file tempfile.path do
          content 'test'
        end
      EOM
      expect(IO.read(tempfile.path)).to eq 'test'
    end

    it "expect_converge { raise 'oh no' }.to raise_error passes" do
      expect_converge {
        raise 'oh no'
      }.to raise_error
    end
  end

  context "when there is a let variable" do
    let(:let_variable) { "test" }

    it "converge { let_variable } accesses it" do
      # Capture the variable outside
      x = nil
      converge { x = let_variable }
      expect(x).to eq 'test'
    end

    it "converge with a file resource referencing let_variable accesses let_variable" do
      converge {
        file tempfile.path do
          content let_variable
        end
      }
      expect(IO.read(tempfile.path)).to eq 'test'
    end
  end
end
