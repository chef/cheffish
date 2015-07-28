require 'support/spec_support'
require 'cheffish/rspec/chef_run_support'

describe 'Cheffish::RSpec::ChefRunSupport#expect_converge' do
  extend Cheffish::RSpec::ChefRunSupport

  context "when there is a let variable" do
    let(:let_variable) { 'hello world' }

    it 'expect_recipe { let_variable } accesses it' do
      # Capture the variable outside
      x = nil
      expect_recipe { x = let_variable }.to be_up_to_date
      expect(x).to eq 'hello world'
    end
  end
end
