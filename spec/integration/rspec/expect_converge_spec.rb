require 'support/spec_support'
require 'cheffish/rspec/chef_run_support'

describe 'Cheffish::RSpec::ChefRunSupport#expect_converge' do
  extend Cheffish::RSpec::ChefRunSupport

  let(:tempfile) { Tempfile.new('test') }

  it "converge { file ... } creates the file" do
    converge {
      file tempfile.path do
        content 'test'
      end
    }
    expect(IO.read(tempfile.path)).to eq 'test'
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
