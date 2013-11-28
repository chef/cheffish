require 'chef/http'
require 'chef/http/authenticator'
require 'chef/http/cookie_manager'
require 'chef/http/decompressor'
require 'chef/http/json_input'
require 'chef/http/json_output'

module Cheffish
  # Just like ServerAPI, except it does not default the server URL or options
  class CheffishServerAPI < Chef::HTTP
    def initialize(chef_server)
      super(chef_server[:chef_server_url], chef_server[:options])
    end

    use Chef::HTTP::JSONInput
    use Chef::HTTP::JSONOutput
    use Chef::HTTP::CookieManager
    use Chef::HTTP::Decompressor
    use Chef::HTTP::Authenticator
  end
end
