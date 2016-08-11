source 'https://rubygems.org'

gemspec

group :changelog do
  gem 'github_changelog_generator'
end

group :development do
  gem 'rake'
  gem 'rspec', '~> 3.0'
end

# Allow Travis to run tests with different dependency versions
if ENV['GEMFILE_MOD']
  puts ENV['GEMFILE_MOD']
  instance_eval(ENV['GEMFILE_MOD'])
else
  group :development do
    gem 'chef', '~> 12.6'
  end
end
