source "https://rubygems.org"
gemspec

# TODO when chef-zero > 4.2.3 is released then just depend on that

gem 'chef-zero', git: 'https://github.com/chef/chef-zero'

if RUBY_VERSION.to_f < 2.0
  gem 'openssl_pkcs8'
end
