$:.unshift(File.dirname(__FILE__) + '/lib')
require 'cheffish/version'

Gem::Specification.new do |s|
  s.name = 'cheffish'
  s.version = Cheffish::VERSION
  s.platform = Gem::Platform::RUBY
  s.extra_rdoc_files = [ 'README.md', 'LICENSE' ]
  s.summary = 'A library to manipulate Chef in Chef.'
  s.description = s.summary
  s.author = 'John Keiser'
  s.email = 'jkeiser@chef.io'
  s.homepage = 'http://github.com/chef/cheffish'

  s.add_dependency 'chef-zero', '~> 4.2'
  s.add_dependency 'chef' , '~> 12.1'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~> 3.0'
  s.bindir       = "bin"
  s.executables  = %w( )

  s.require_path = 'lib'
  s.files = %w(Rakefile LICENSE README.md) + Dir.glob("{distro,lib,tasks,spec}/**/*", File::FNM_DOTMATCH).reject {|f| File.directory?(f) }
end
