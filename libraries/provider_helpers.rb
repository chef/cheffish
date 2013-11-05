require 'chef/server_api'
require 'chef/config'

module Cheffish
  module ProviderHelpers
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
      keys.each do |key|
        value = resource.send(key.to_sym)
        json[key] = value if value
      end
      json
    end

    def json_to_resource(json)
      resource = resource_class.new(new_resource.name)
      keys.each do |key|
        resource.send(key.to_sym, json[key])
      end
      resource
    end

    def normalize(json)
      data_handler.normalize(json, fake_entry)
    end

    private

    # Needed to be able to use DataHandler classes
    def fake_entry
      FakeEntry.new(new_resource.send(keys[0].to_sym))
    end

    class FakeEntry
      def initialize(name)
        @name = "#{name}.json"
      end

      attr_reader :name
    end
  end
end