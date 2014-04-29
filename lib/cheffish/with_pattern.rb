module Cheffish
  module WithPattern
    def with(symbol)
      class_eval <<EOM
        attr_accessor :current_#{symbol}

        def with_#{symbol}(value)
          old_value = self.current_#{symbol}
          self.current_#{symbol} = value
          if block_given?
            begin
              yield
            ensure
              self.current_#{symbol} = old_value
            end
          end
        end
EOM
    end
  end
end
