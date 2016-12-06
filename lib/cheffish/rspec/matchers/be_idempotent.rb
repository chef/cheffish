require "rspec/matchers"

RSpec::Matchers.define :be_idempotent do
  match do |recipe|
    @recipe = recipe
    recipe.reset
    recipe.converge
    recipe.up_to_date?
  end

  failure_message do
    "#{@recipe} is not idempotent!  Converging it a second time caused updates.\n#{@recipe.output_for_failure_message}"
  end

  supports_block_expectations
end
