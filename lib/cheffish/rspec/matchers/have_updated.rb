require "rspec/matchers"

RSpec::Matchers.define :have_updated do |resource_name, *expected_actions|
  match do |recipe|
    @recipe = recipe
    actual = @recipe.event_sink.events
    actual_actions = actual.select { |event, resource, action| event == :resource_updated && resource.to_s == resource_name }.
                               map { |event, resource, action| action }
    expect(actual_actions).to eq(expected_actions)
  end

  failure_message do
    actual = @recipe.event_sink.events
    updates = actual.select { |event, resource, action| event == :resource_updated }.to_a
    result = "expected that the chef_run would #{expected_actions.join(',')} #{resource_name}."
    if updates.size > 0
      result << " Actual updates were #{updates.map { |event, resource, action| "#{resource} => #{action.inspect}" }.join(', ')}"
    else
      result << " Nothing was updated."
    end
    result
  end

  failure_message_when_negated do
    actual = @recipe.event_sink.events
    updates = actual.select { |event, resource, action| event == :resource_updated }.to_a
    result = "expected that the chef_run would not #{expected_actions.join(',')} #{resource_name}."
    if updates.size > 0
      result << " Actual updates were #{updates.map { |event, resource, action| "#{resource} => #{action.inspect}" }.join(', ')}"
    else
      result << " Nothing was updated."
    end
    result
  end
end

RSpec::Matchers.define_negated_matcher :not_have_updated, :have_updated
