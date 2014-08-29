require 'chef/resource/lwrp_base'

class Chef::Resource::ChefResolvedCookbooks < Chef::Resource::LWRPBase
  self.resource_name = 'chef_resolved_cookbooks'

  actions :resolve, :nothing
  default_action :resolve

  def initialize(*args)
    super
    require 'berkshelf'
    berksfile Berkshelf::Berksfile.new('/tmp/Berksfile')
    chef_server run_context.cheffish.current_chef_server
    @cookbooks_from = []
  end

  extend Forwardable

  def_delegators :@berksfile, :cookbook, :extension, :group, :metadata, :source

  def cookbooks_from(path = nil)
    if path
      @cookbooks_from << path
    else
      @cookbooks_from
    end
  end

  attribute :berksfile
  attribute :chef_server
end
