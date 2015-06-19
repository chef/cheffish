module Cheffish
  module RSpec
    module Matchers
      #
      # Match a partial expected value against an actual
      # value.  Tries to give good deep output as well,
      # telling you exactly what suceeded and what failed.
      # Supports matchers anywhere in the specification.
      #
      # Expected hashes check to see if those keys are in the
      # hash and if the values match as well: `{ a: 1 }` will
      # match `{ a: 1, b: 2 }`, and will fail `{ a: 2 }` with
      # "a: expected 1, got 2" and fail `{ b: 2 }` with "a:
      # expected key to exist in the hash, but it does not."
      #
      # Nested hashes work as well: `{ a: { b: 1 } }` will
      # match `{ a: { b: 1, c: 2 }, d: 3 }` and fail
      # `{ a: 1 }`, `{ x: 1 }`, `{ a: { b: 1 }}` and `{ a: { x: 1 }}`.
      #
      # Arrays do an *unordered* check to see if all values in
      # the expected array are in the actual array.  Duplicates
      # are allowed and verified; [ 2, 2 ] does not match [ 1 ]
      # and [ gt(2), gt(2) ] does not match [ 3 ].
      #
      # NOTE: no attempt is made to try different combinations
      # of matchers.  The expected values are run in order and each
      # consume the first value they run across.  This means that
      # `[ gt(0), 1 ]` will NOT match `[ 1, 2 ]`, because the
      # `gt(0)` will match the `1`.
      #
      # Nested values give deep error messages:
      #
      # ```ruby
      # { a: { b: 1, c: 2 }, c: 3 }.match({ a: { b: 2, x: 2 }})
      # # yields
      # expected { a: { b: 1, c: 2 }, d: 3 }, got { a: { b: 2 }}.
      # Differences:
      # a.b: expected 1, got 2
      # a.c: expected key 'c', key was missing
      # d  : expected key 'd', key was key missing
      # ```
      #
      # You may use matchers anywhere in the value, and match will
      # be called and the failure description reported.
      #
      class DeeplyMatch
        include ::RSpec::Matchers::Composable

        def initialize(example, expected, fail_on_extra_values: true)
          @example = example
          @expected = expected
          @fail_on_extra_values = fail_on_extra_values
        end

        def matches?(actual)
          @actual = actual
          deep_match_failures(@expected, actual)
        end

        def failure_message
          "expected #{@actual} to match #{@expected}!"
        end

        def failure_message_when_negated
          "expected #{@actual} not to match #{@expected}"
        end

        protected

        def deep_match_failures(expected, actual)
          if Hash === actual
            return deep_match_hashes(expected, actual) if Hash === expected || Array === expected
          elsif Array === expected && Enumerable === actual && !(Struct === actual)
            return deep_match_arrays(expected, actual)
          end

          return nil if actual == expected

          if expected.is_a?(RSpec::Matchers::Composable)
            if expected.matches?(actual)
              nil
            else
              expected.failure_message
            end
          else

          begin
            expected === actual
          rescue ArgumentError
            # Some objects, like 0-arg lambdas on 1.9+, raise
            # ArgumentError for `expected === actual`.
            "expected #{description_for(expected)}, got #{description_for(actual)}"
          end
        end

        #
        # + foo:  1
        # - blah: missing, expected it to be 4
        #   blah: expected 2
        #
        def deep_match_hashes(expected_hash, actual_hash)
          failure_messages = {}
          remaining_actual_keys = actual_hash.keys.to_set
          expected_hash.each do |key, expected|
            if remaining_actual_keys.delete(key)
              failures = deep_match_values(value, actual_hash[key])
              failure_messages[key] = failures if failures
            else
              failure_messages[key] = prefix("-", "missing key #{key}, expected #{description_for(expected)}"
            end
          end

          if fail_on_extra_values
            remaining_actual_keys.each do |key|
              failure_messages[key] = prefix("+", "unexpected key #{key} with value #{description_for(actual_hash[key])}")
            end
          end

          failure_messages.empty? ? nil : failure_messages
        end

        def deep_match_arrays(expected_array, actual_array)
          failure_messages = {}

          actual_remaining = actual_array.map { |x| x }
          expected_array.each do |expected|
            matched = false
            actual_remaining.each_with_index do |actual, index|
              failures = deep_match_failures(expected, actual)
              if failures.empty? # match
                matched = true
                add_failures(failure_messages, "[#{matched}]" => failures)
                actual_remaining.delete_at(actual_index)
                break
              end
            end
            if !matched
              add_failures(failure_messages, '' => "missing #{description_for(expected)}")
            end
          end

          if @fail_on_extra_values
            actual_remaining.each do |actual|
              add_failures(failure_messages, '' => "unexpected value #{description_for(actual)}")
            end
          end

          failure_messages
        end

        # a.b[0].c: missing key 'c'
        # a.b:

        def with_eol(str)
          str.end_with?("\n") ? str : "#{str}\n"
        end

        def prefix(prefix, str)
          return str if str.empty?

          first = true
          str = str.lines.map do |line|
          end.join("")
          with_eol(str)
        end
      end
    end
  end
end

module RSpec
  module Matchers
    def deeply_match(expected)
      Cheffish::RSpec::Matchers::deeplyMatch.new(self, expected)
    end
  end
end
