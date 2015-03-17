RSpec::Matchers.define :have_updated do |resource_name, *expected_actions|
  match do |actual|
    actual_actions = actual.select { |event, resource, action| event == :resource_updated && resource.to_s == resource_name }.map { |event, resource, action| action }
    expect(actual_actions).to eq(expected_actions)
  end
  failure_message do |actual|
    updates = actual.select { |event, resource, action| event == :resource_updated }.to_a
    result = "expected that the chef_run would #{expected_actions.join(',')} #{resource_name}."
    if updates.size > 0
      result << " Actual updates were #{updates.map { |event, resource, action| "#{resource.to_s} => #{action.inspect}" }.join(', ')}"
    else
      result << " Nothing was updated."
    end
    result
  end
  failure_message_when_negated do |actual|
    updates = actual.select { |event, resource, action| event == :resource_updated }.to_a
    result = "expected that the chef_run would not #{expected_actions.join(',')} #{resource_name}."
    if updates.size > 0
      result << " Actual updates were #{updates.map { |event, resource, action| "#{resource.to_s} => #{action.inspect}" }.join(', ')}"
    else
      result << " Nothing was updated."
    end
    result
  end
end

RSpec::Matchers.define :update_acls do |acl_paths, expected_acls|

  errors = []

  match do |block|
    orig_json = {}
    Array(acl_paths).each do |acl_path|
      orig_json[acl_path] = get(acl_path)
    end

    block.call

    orig_json.each_pair do |acl_path, orig|
      changed = get(acl_path)
      expected_acls.each do |permission, hash|
        hash.each do |type, actors|
          actors.each do |actor|
            if actor[0] == '-'
              actor = actor[1..-1]
              errors << "#{acl_path} expected to remove #{type} #{actor} from #{permission} permissions" if changed[permission][type].include?(actor)
              orig[permission][type].delete(actor)
            else
              errors << "#{acl_path} expected to add #{type} #{actor} to #{permission} permissions" if !changed[permission][type].include?(actor)
              changed[permission][type].delete(actor)
            end
          end
        end
      end
      # After checking everything, see if the remaining acl is the same as before
      errors << "#{acl_path} updated more than expected!\nActual:\n#{changed}\nExpected:\n#{orig}" if changed != orig
    end
    errors.size == 0
  end

  failure_message do |block|
    errors.join("\n")
  end

  supports_block_expectations
end
