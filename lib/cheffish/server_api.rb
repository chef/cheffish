#
# Author:: John Keiser (<jkeiser@opscode.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "chef/version"
require "chef/http"
require "chef/http/authenticator"
require "chef/http/cookie_manager"
require "chef/http/decompressor"
require "chef/http/json_input"
require "chef/http/json_output"
if Gem::Version.new(Chef::VERSION) >= Gem::Version.new("11.12")
  require "chef/http/remote_request_id"
end

module Cheffish
  # Exactly like Chef::ServerAPI, but requires you to pass in what keys you want (no defaults)
  class ServerAPI < Chef::HTTP

    def initialize(url, options = {})
      super(url, options)
      root_url = URI.parse(url)
      root_url.path = ""
      @root_url = root_url.to_s
    end

    attr_reader :root_url

    use Chef::HTTP::JSONInput
    use Chef::HTTP::JSONOutput
    use Chef::HTTP::CookieManager
    use Chef::HTTP::Decompressor
    use Chef::HTTP::Authenticator
    if Gem::Version.new(Chef::VERSION) >= Gem::Version.new("11.12")
      use Chef::HTTP::RemoteRequestID
    end
  end
end
