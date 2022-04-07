source "https://rubygems.org"

gemspec

group :development do
  gem "chefstyle", "2.0.8"
  gem "rake"
  gem "rspec", "~> 3.0"
end

# Allow Travis to run tests with different dependency versions
if ENV["GEMFILE_MOD"]
  puts ENV["GEMFILE_MOD"]
  instance_eval(ENV["GEMFILE_MOD"])
else
  group :development do
    gem "chef", github: "chef/chef", branch: "main"
    gem "ohai", github: "chef/ohai", branch: "main"
  end
end
