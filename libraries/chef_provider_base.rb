require 'chef/server_api'
require 'chef/config'
require 'chef/run_list'

module Cheffish
  class ChefProviderBase < Chef::Provider::LWRPBase
    def rest
      @rest ||= Chef::ServerAPI.new(Chef::Config.chef_server_url)
    end

    def current_resource_exists?
      Array(current_resource.action) != [ :delete ]
    end

    def not_found_resource
      resource = resource_class.new(new_resource.name)
      resource.action :delete
      resource
    end

    def normalize_for_put(json)
      data_handler.normalize(json, fake_entry)
    end

    def normalize_for_post(json)
      data_handler.normalize(json, fake_entry)
    end

    def new_json
      @new_json ||= begin
        if new_resource.complete
          normalize(resource_to_json(new_resource))
        else
          # If resource is incomplete, use current json to fill any holes
          current_json.merge(resource_to_json(new_resource))
        end
      end
    end

    def current_json
      @current_json ||= normalize(resource_to_json(current_resource))
    end

    def resource_to_json(resource)
      json = {}
      keys.each do |json_key, resource_key|
        value = resource.send(resource_key)
        json[json_key] = value if value
      end
      json
    end

    def json_to_resource(json)
      resource = resource_class.new(new_resource.name)
      keys.each do |json_key, resource_key|
        resource.send(resource_key, json[json_key])
      end
      resource
    end

    def normalize(json)
      data_handler.normalize(json, fake_entry)
    end

    def json_differences(old_json, new_json, name = '')
      if old_json == new_json
        []
      elsif old_json.kind_of?(Hash) && old_json.kind_of?(Hash)
        result = []
        removed_keys = old_json.keys.inject({}) { |hash, key| hash[key] = true; hash }
        new_json.each_pair do |new_key, new_value|
          if old_json.has_key?(new_key)
            removed_keys.delete(new_key)
            if new_value != old_json[new_key]
              result += json_differences(old_json[new_key], new_value, name == '' ? new_key : "#{name}.#{new_key}")
            end
          else
            result << "add #{name == '' ? new_key : "#{name}.#{new_key}"} = #{new_value.inspect}"
          end
        end
        removed_keys.keys.each do |removed_key|
          result << "remove #{name == '' ? removed_key : "#{name}.#{removed_key}"}"
        end
        result
      else
        return [ "update #{name} from #{old_json.inspect} to #{new_json.inspect}" ]
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
        parent = path[0..-2].inject(json) { |hash, path_part| hash ? hash[path_part] : nil }
        existing_value = parent ? parent[path[-1]] : nil

        if value.is_a?(Proc)
          value = value.call(existing_value)
        end
        if value == :delete
          parent.delete(path[-1]) if parent
          # TODO clean up parent chain if hash is completely emptied
        else
          if !parent
            # Create parent if necessary
            parent = path[0..-2].inject(json) do |hash, path_part|
              hash[path_part] = {} if !hash[path_part]
              hash[path_part]
            end
          end
          parent[path[-1]] = value
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
      while run_list_index < run_list.run_list_items.size do
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
            add_to_run_list_index = found_desired+1
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
      end

      attr_reader :name
      attr_reader :parent
    end
  end
end