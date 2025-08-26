$:.unshift(File.dirname(__FILE__) + "/lib")
require "cheffish/version"

Gem::Specification.new do |s|
  s.name = "cheffish"
  s.version = Cheffish::VERSION
  s.platform = Gem::Platform::RUBY
  s.license = "Apache-2.0"
  s.summary = "A set of Chef resources for configuring Chef Infra."
  s.description = s.summary
  s.author = "Chef Software Inc."
  s.email = "oss@chef.io"
  s.homepage = "https://github.com/chef/cheffish"

  s.required_ruby_version = ">= 3.1"

  s.add_dependency "chef-zero", ">= 14.0"
  s.add_dependency "chef-utils", ">= 17.0"
  s.add_dependency "logger", "< 1.6.0"
  s.add_dependency "net-ssh"
  s.add_dependency "syslog"

  s.require_path = "lib"
  s.files = %w{Gemfile Rakefile LICENSE} + Dir.glob("*.gemspec") +
    Dir.glob("{lib,spec}/**/*", File::FNM_DOTMATCH).reject { |f| File.directory?(f) }
end
