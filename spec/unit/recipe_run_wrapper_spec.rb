require "support/spec_support"
require "cheffish/rspec/chef_run_support"
# require 'cheffish/rspec/recipe_run_wrapper'

module MyModule
  def respond_to_missing?(name, *args)
    if name == :allowable_method
      true
    else
      false
    end
  end
end

describe Cheffish::RSpec::RecipeRunWrapper do
  extend Cheffish::RSpec::ChefRunSupport

  let(:run_wrapper) do
    Cheffish::RSpec::RecipeRunWrapper.new(chef_config) do
      log "test recipe in specs"
    end
  end

  context "defines #respond_to_missing? on the client" do
    it "calls the new super.respond_to_missing" do
      run_wrapper.client.extend MyModule
      expect(run_wrapper.client.respond_to?(:allowable_method)).to be_truthy
      expect(run_wrapper.client.respond_to?(:not_an_allowable_method)).to be_falsey
    end
  end

  context "does not define #respond_to_missing? on the client" do
    it "calls the original super.respond_to_missing" do
      expect(run_wrapper.client.respond_to?(:nonexistent_method)).to be_falsey
    end
  end
end
