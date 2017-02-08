require "chef/mash"

module Cheffish
  class MergedConfig
    def initialize(*configs)
      @configs = configs.map { |config| Chef::Mash.from_hash config }
      @merge_arrays = Chef::Mash.new
    end

    include Enumerable

    attr_reader :configs
    def merge_arrays(*symbols)
      if symbols.size > 0
        symbols.each do |symbol|
          @merge_arrays[symbol] = true
        end
      else
        @merge_arrays
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

    def method_missing(name, *args)
      if args.count > 0
        raise NoMethodError, "Unexpected method #{name} for MergedConfig with arguments #{args}"
      else
        self[name]
      end
    end

    def key?(name)
      configs.any? { |config| config.has_key?(name) }
    end

    alias_method :has_key?, :key?

    def keys
      configs.flat_map { |c| c.keys }.uniq
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

    def to_hash
      result = {}
      each_pair do |key, value|
        result[key] = value
      end
      result
    end

    def to_h
      to_hash
    end

    def to_s
      to_hash.to_s
    end
  end
end
