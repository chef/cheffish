source 'https://rubygems.org'

# Specify your gem's dependencies in ruby-project-template.gemspec
gemspec

group :development do
  gem 'rake'
  gem 'rspec', '~> 3.0'
end

group :changelog do
  gem 'github_changelog_generator'
end

# Allow Travis to run tests with different dependency versions
if ENV['GEMFILE_MOD']
  puts ENV['GEMFILE_MOD']
  instance_eval(ENV['GEMFILE_MOD'])
end
