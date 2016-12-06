require "rspec/matchers"

RSpec::Matchers.define :emit_no_warnings_or_errors do
  match do |recipe|
    @recipe = recipe
    @warn_err = recipe.logs.lines.select { |l| l =~ /warn|err/i }.join("\n")
    @warn_err.empty?
  end

  failure_message do
    "#{@recipe} emitted warnings and errors!\n#{@warn_err}"
  end

  supports_block_expectations
end
