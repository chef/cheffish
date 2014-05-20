module Cheffish
  class MergedConfig
    def initialize(*configs)
      @configs = configs
      @merge_arrays = {}
    end

    attr_reader :configs
    def merge_arrays(*symbols)
      symbols.each do |symbol|
        @merge_arrays[symbol] = true
      end
    end

    def [](name)
      if @merge_arrays[name]
        configs.select { |c| !c[name].nil? }.collect_concat { |c| c[name] }
      else
        result_configs = []
        configs.each do |config|
          value = config[name]
          if !value.nil?
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
    end

    def method_missing(name)
      self[name]
    end

    def has_key?(name)
      configs.any? { config.has_key?(name) }
    end

    def keys
      configs.map { |c| c.keys }.flatten(1).uniq
    end

    def values
      keys.map { |key| self[key] }
    end

    def each_pair(&block)
      each(&block)
    end

    def each
      keys.each do |key|
        if block_given?
          yield key, self[key]
        end
      end
    end
  end
end
