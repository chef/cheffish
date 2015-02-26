source "https://rubygems.org"
gemspec

if RUBY_VERSION.to_f < 2.0
  gem 'openssl_pkcs8'
end

# TODO comment this out when 12.1 is released and pin in gemspec
gem 'chef', :github => 'opscode/chef', :branch => 'tball/include_shellout' #:path => '../chef'
#gem 'chef-zero', :path => '../chef-zero'
