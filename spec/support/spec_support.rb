require 'chef_zero/rspec'
require 'chef/recipe'
require 'chef/run_context'
require 'chef/event_dispatch/dispatcher'
require 'chef/cookbook/cookbook_collection'
require 'chef/runner'
require 'chef/server_api'

module SpecSupport
  include ChefZero::RSpec

  def self.extended(klass)
    klass.class_eval do
      def get(*args)
        Chef::ServerAPI.new.get(*args)
      end

      def chef_run
        @event_sink.events
      end

      def run_recipe(&block)
        node = Chef::Node.new
        node.name 'test'
        node.automatic[:platform] = 'test'
        node.automatic[:platform_version] = 'test'
        @event_sink ||= EventSink.new
        run_context = Chef::RunContext.new(node, {}, Chef::EventDispatch::Dispatcher.new(@event_sink))
        recipe = Chef::Recipe.new('test', 'test', run_context)
        recipe.instance_eval(&block)
        Chef::Runner.new(run_context).converge
      end
    end
  end

  def run_recipe_before(&block)
    before :each do
      run_recipe(&block)
    end
  end

  class EventSink
    def initialize
      @events = []
    end

    attr_reader :events

    def method_missing(method, *args)
      @events << [ method, *args ]
    end
  end
end

RSpec::Matchers.define :have_updated do |resource_name, expected_action|
  match do |actual|
    actual.any? { |event, resource, action| event == :resource_updated && action == expected_action && resource.to_s == resource_name }
  end
end


# Stuff that should have been required in Chef, but wasn't (Chef will be fixed)
require 'chef/platform'

require 'chef/provider/service/simple'
require 'chef/provider/service/init'

require 'chef/provider/cron'
require 'chef/provider/cron/aix'
require 'chef/provider/cron/solaris'
require 'chef/provider/directory'
require 'chef/provider/env/windows'
require 'chef/provider/erl_call'
require 'chef/provider/execute'
require 'chef/provider/file'
require 'chef/provider/group/aix'
require 'chef/provider/group/dscl'
require 'chef/provider/group/gpasswd'
require 'chef/provider/group/groupmod'
require 'chef/provider/group/pw'
require 'chef/provider/group/suse'
require 'chef/provider/group/usermod'
require 'chef/provider/group/windows'
require 'chef/provider/http_request'
require 'chef/provider/ifconfig'
require 'chef/provider/ifconfig/aix'
require 'chef/provider/ifconfig/debian'
require 'chef/provider/ifconfig/redhat'
require 'chef/provider/link'
require 'chef/provider/log'
require 'chef/provider/mdadm'
require 'chef/provider/mount/aix'
require 'chef/provider/mount/mount'
require 'chef/provider/mount/windows'
require 'chef/provider/package/aix'
require 'chef/provider/package/apt'
require 'chef/provider/package/freebsd'
require 'chef/provider/package/ips'
require 'chef/provider/package/macports'
require 'chef/provider/package/pacman'
require 'chef/provider/package/portage'
require 'chef/provider/package/solaris'
require 'chef/provider/package/smartos'
require 'chef/provider/package/yum'
require 'chef/provider/package/zypper'
require 'chef/provider/remote_directory'
require 'chef/provider/route'
require 'chef/provider/ruby_block'
require 'chef/provider/script'
require 'chef/provider/service/arch'
require 'chef/provider/service/debian'
require 'chef/provider/service/freebsd'
require 'chef/provider/service/gentoo'
require 'chef/provider/service/init'
require 'chef/provider/service/insserv'
require 'chef/provider/service/macosx'
require 'chef/provider/service/redhat'
require 'chef/provider/service/solaris'
require 'chef/provider/service/upstart'
require 'chef/provider/service/windows'
require 'chef/provider/template'
require 'chef/provider/user/dscl'
require 'chef/provider/user/pw'
require 'chef/provider/user/useradd'
require 'chef/provider/user/solaris'
require 'chef/provider/user/windows'
