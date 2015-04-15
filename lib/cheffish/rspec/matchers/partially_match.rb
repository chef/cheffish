module Cheffish
  module RSpec
    module Matchers
      class PartiallyMatch
        include ::RSpec::Matchers::Composable

        def initialize(example, expected)
          @example = example
          @expected = expected
        end

        def matches?(actual)
          @actual = actual
          partially_matches_values(@expected, actual)
        end

        def failure_message
          "expected #{@actual} to match #{@expected}"
        end

        def failure_message_when_negated
          "expected #{@actual} not to match #{@expected}"
        end

        protected

        def partially_matches_values(expected, actual)
          if Hash === actual
            return partially_matches_hashes(expected, actual) if Hash === expected || Array === expected
          elsif Array === expected && Enumerable === actual && !(Struct === actual)
            return partially_matches_arrays(expected, actual)
          end

          return true if actual == expected

          begin
            expected === actual
          rescue ArgumentError
            # Some objects, like 0-arg lambdas on 1.9+, raise
            # ArgumentError for `expected === actual`.
            false
          end
        end

        def partially_matches_hashes(expected, actual)
          expected.all? { |key, value| partially_matches_values(value, actual[key]) }
        end

        def partially_matches_arrays(expected, actual)
          expected.all? { |e| actual.any? { |a| partially_matches_values(e, a) } }
        end
      end
    end
  end
end

module RSpec
  module Matchers
    def partially_match(expected)
      Cheffish::RSpec::Matchers::PartiallyMatch.new(self, expected)
    end
  end
end
