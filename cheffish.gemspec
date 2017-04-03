$:.unshift(File.dirname(__FILE__) + "/lib")
require "cheffish/version"

Gem::Specification.new do |s|
  s.name = "cheffish"
  s.version = Cheffish::VERSION
  s.platform = Gem::Platform::RUBY
  s.extra_rdoc_files = [ "README.md", "LICENSE" ]
  s.summary = "A library to manipulate Chef in Chef."
  s.description = s.summary
  s.author = "John Keiser"
  s.email = "jkeiser@chef.io"
  s.homepage = "http://github.com/chef/cheffish"

  s.required_ruby_version = ">= 2.3.3"

  s.add_dependency "chef-zero", "~> 13.0"
  s.add_dependency "net-ssh"

  s.bindir       = "bin"
  s.executables  = %w{ }

  s.require_path = "lib"
  s.files = %w{Gemfile Rakefile LICENSE README.md} + Dir.glob("*.gemspec") +
    Dir.glob("{distro,lib,tasks,spec}/**/*", File::FNM_DOTMATCH).reject { |f| File.directory?(f) }
end
