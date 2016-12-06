require "chef/property"

module Cheffish
  # A typical array property. Defaults to [], accepts multiple args to setter, accumulates values.
  class ArrayProperty < Chef::Property
    def initialize(**options)
      options[:is] ||= Array
      options[:default] ||= []
      options[:coerce] ||= proc { |v| v.is_a?(Array) ? v : [ v ] }
      super
    end

    # Support my_property 'a', 'b', 'c'; my_property 'a'; and my_property ['a', 'b']
    def emit_dsl
      declared_in.class_eval(<<-EOM, __FILE__, __LINE__ + 1)
        def #{name}(*values)
          property = self.class.properties[#{name.inspect}]
          if values.empty?
            property.get(self)
          elsif property.is_set?(self)
            property.set(self, property.get(self) + values.flatten)
          else
            property.set(self, values.flatten)
          end
        end
      EOM
    end
  end
end
