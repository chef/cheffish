require "chef/resource"
require "cheffish/base_properties"

module Cheffish
  class BaseResource < Chef::Resource
    include Cheffish::BaseProperties

    declare_action_class.class_eval do
      def rest
        @rest ||= Cheffish.chef_server_api(new_resource.chef_server)
      end

      def current_resource_exists?
        Array(current_resource.action) != [ :delete ]
      end

      def not_found_resource
        resource = resource_class.new(new_resource.name, run_context)
        resource.action :delete
        resource
      end

      def normalize_for_put(json)
        data_handler.normalize_for_put(json, fake_entry)
      end

      def normalize_for_post(json)
        data_handler.normalize_for_post(json, fake_entry)
      end

      def new_json
        @new_json ||= begin
          if new_resource.complete
            result = normalize(resource_to_json(new_resource))
          else
            # If the resource is incomplete, we use the current json to fill any holes
            result = current_json.merge(resource_to_json(new_resource))
          end
          augment_new_json(result)
        end
      end

      # Meant to be overridden
      def augment_new_json(json)
        json
      end

      def current_json
        @current_json ||= begin
          result = normalize(resource_to_json(current_resource))
          result = augment_current_json(result)
          result
        end
      end

      # Meant to be overridden
      def augment_current_json(json)
        json
      end

      def resource_to_json(resource)
        json = resource.raw_json || {}
        keys.each do |json_key, resource_key|
          value = resource.send(resource_key)
          # This takes care of Chef ImmutableMash and ImmutableArray
          value = value.to_hash if value.is_a?(Hash)
          value = value.to_a if value.is_a?(Array)
          json[json_key] = value if value
        end
        json
      end

      def json_to_resource(json)
        resource = resource_class.new(new_resource.name, run_context)
        keys.each do |json_key, resource_key|
          resource.send(resource_key, json.delete(json_key))
        end
        # Set the leftover to raw_json
        resource.raw_json json
        resource
      end

      def normalize(json)
        data_handler.normalize(json, fake_entry)
      end

      def json_differences(old_json, new_json, print_values = true, name = "", result = nil)
        result ||= []
        json_differences_internal(old_json, new_json, print_values, name, result)
        result
      end

      def json_differences_internal(old_json, new_json, print_values, name, result)
        if old_json.kind_of?(Hash) && new_json.kind_of?(Hash)
          removed_keys = old_json.keys.inject({}) { |hash, key| hash[key] = true; hash }
          new_json.each_pair do |new_key, new_value|
            if old_json.has_key?(new_key)
              removed_keys.delete(new_key)
              if new_value != old_json[new_key]
                json_differences_internal(old_json[new_key], new_value, print_values, name == "" ? new_key : "#{name}.#{new_key}", result)
              end
            else
              if print_values
                result << "  add #{name == '' ? new_key : "#{name}.#{new_key}"} = #{new_value.inspect}"
              else
                result << "  add #{name == '' ? new_key : "#{name}.#{new_key}"}"
              end
            end
          end
          removed_keys.keys.each do |removed_key|
            result << "  remove #{name == '' ? removed_key : "#{name}.#{removed_key}"}"
          end
        else
          old_json = old_json.to_s if old_json.kind_of?(Symbol)
          new_json = new_json.to_s if new_json.kind_of?(Symbol)
          if old_json != new_json
            if print_values
              result << "  update #{name} from #{old_json.inspect} to #{new_json.inspect}"
            else
              result << "  update #{name}"
            end
          end
        end
      end

      def apply_modifiers(modifiers, json)
        return json if !modifiers || modifiers.size == 0

        # If the attributes have nothing, set them to {} so we have something to add to
        if json
          json = Marshal.load(Marshal.dump(json)) # Deep copy
        else
          json = {}
        end

        modifiers.each do |path, value|
          path = [path] if !path.kind_of?(Array)
          path = path.map { |path_part| path_part.to_s }
          parent = 0.upto(path.size - 2).inject(json) do |hash, index|
            if hash.nil?
              nil
            elsif !hash.is_a?(Hash)
              raise "Attempt to set #{path} to #{value} when #{path[0..index - 1]} is not a hash"
            else
              hash[path[index]]
            end
          end
          if !parent.nil? && !parent.is_a?(Hash)
            raise "Attempt to set #{path} to #{value} when #{path[0..-2]} is not a hash"
          end
          existing_value = parent ? parent[path[-1]] : nil

          if value.is_a?(Proc)
            value = value.call(existing_value)
          end
          if value == :delete
            parent.delete(path[-1]) if parent
          else
            # Create parent if necessary, overwriting values
            parent = path[0..-2].inject(json) do |hash, path_part|
              hash[path_part] = {} if !hash[path_part]
              hash[path_part]
            end
            if path.size > 0
              parent[path[-1]] = value
            else
              json = value
            end
          end
        end
        json
      end

      def apply_run_list_modifiers(add_to_run_list, delete_from_run_list, run_list)
        return run_list if (!add_to_run_list || add_to_run_list.size == 0) && (!delete_from_run_list || !delete_from_run_list.size)
        delete_from_run_list ||= []
        add_to_run_list ||= []

        run_list = Chef::RunList.new(*run_list)

        result = []
        add_to_run_list_index = 0
        run_list_index = 0
        while run_list_index < run_list.run_list_items.size
          # See if the desired run list has this item
          found_desired = add_to_run_list.index { |item| same_run_list_item(item, run_list[run_list_index]) }
          if found_desired
            # If so, copy all items up to that desired run list (to preserve order).
            # If a run list item is out of order (run_list = X, B, Y, A, Z and desired = A, B)
            # then this will give us X, A, B.  When A is found later, nothing will be copied
            # because found_desired will be less than add_to_run_list_index.  The result will
            # be X, A, B, Y, Z.
            if found_desired >= add_to_run_list_index
              result += add_to_run_list[add_to_run_list_index..found_desired].map { |item| item.to_s }
              add_to_run_list_index = found_desired + 1
            end
          else
            # If not, just copy it in
            unless delete_from_run_list.index { |item| same_run_list_item(item, run_list[run_list_index]) }
              result << run_list[run_list_index].to_s
            end
          end
          run_list_index += 1
        end

        # Copy any remaining desired items at the end
        result += add_to_run_list[add_to_run_list_index..-1].map { |item| item.to_s }
        result
      end

      def same_run_list_item(a, b)
        a_name = a.name
        b_name = b.name
        # Handle "a::default" being the same as "a"
        if a.type == :recipe && a_name =~ /(.+)::default$/
          a_name = $1
        elsif b.type == :recipe && b_name =~ /(.+)::default$/
          b_name = $1
        end

        a_name == b_name && a.type == b.type # We want to replace things with same name and different version
      end

      private

      # Needed to be able to use DataHandler classes
      def fake_entry
        FakeEntry.new("#{new_resource.send(keys.values.first)}.json")
      end

      class FakeEntry
        def initialize(name, parent = nil)
          @name = name
          @parent = parent
          @org = nil
        end

        attr_reader :name
        attr_reader :parent
        attr_reader :org
      end
    end
  end
end
