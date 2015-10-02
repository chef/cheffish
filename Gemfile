source 'https://rubygems.org'

# Specify your gem's dependencies in ruby-project-template.gemspec
gemspec
gem 'chef', path: '../chef'
gem 'compat_resource', path: '../cookbooks/compat_resource'

# Allow Travis to run tests with different dependency versions
if ENV['GEMFILE_MOD']
  puts ENV['GEMFILE_MOD']
  instance_eval(ENV['GEMFILE_MOD'])
end
