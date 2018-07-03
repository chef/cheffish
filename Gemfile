source "https://rubygems.org"

gemspec

group :development do
  gem "chefstyle", git: "https://github.com/chef/chefstyle.git", branch: "master"
  gem "rake"
  gem "rspec", "~> 3.0"
end

# Allow Travis to run tests with different dependency versions
if ENV["GEMFILE_MOD"]
  puts ENV["GEMFILE_MOD"]
  instance_eval(ENV["GEMFILE_MOD"])
else
  group :development do
    gem "chef", "~> 14"
    gem "ohai", "~> 14"
  end
end
