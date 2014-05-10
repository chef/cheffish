module Cheffish
  class MergedConfig
    def initialize(*configs)
      @configs = configs
    end

    attr_reader :configs

    def [](name)
      result_configs = []
      configs.each do |config|
        value = config[name]
        if value
          if value.respond_to?(:keys)
            result_configs << value
          elsif result_configs.size > 0
            return result_configs[0]
          else
            return value
          end
        end
      end
      if result_configs.size > 1
        MergedConfig.new(*result_configs)
      elsif result_configs.size == 1
        result_configs[0]
      else
        nil
      end
    end

    def method_missing(name)
      self[name]
    end
  end
end
