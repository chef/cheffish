require 'cheffish/rspec'

require 'cheffish'
require 'chef/provider/chef_acl'

RSpec.configure do |config|
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true

  config.before :each do
    Chef::Config.reset
  end
end

require 'chef/providers'
