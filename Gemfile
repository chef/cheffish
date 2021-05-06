source "https://rubygems.org"

gemspec

group :development do
  gem "chefstyle", "2.0.3"
  gem "rake"
  gem "rspec", "~> 3.0"
end


# Allow Travis to run tests with different dependency versions
if ENV["GEMFILE_MOD"]
  puts ENV["GEMFILE_MOD"]
  instance_eval(ENV["GEMFILE_MOD"])
else
  group :development do
    # temporarily we only support building against master
    gem "chef", github: "chef/chef", branch: "master"
    gem "ohai", github: "chef/ohai", branch: "master"
    # gem "chef", "~> 16"
    # gem "ohai", "~> 16"
  end
end

group :docs do
  gem "yard"
  gem "redcarpet"
  gem "github-markup"
end

group :debug do
  gem "pry"
  gem "pry-byebug"
  gem "pry-stack_explorer"
  gem "rb-readline"
end
