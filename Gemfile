source "https://rubygems.org"

gemspec

group :changelog do
  gem "github_changelog_generator", git: "https://github.com/tduffield/github-changelog-generator", branch: "adjust-tag-section-mapping"
end

group :development do
  gem "chefstyle"
  gem "rake"
  gem "rspec", "~> 3.0"
end

# Allow Travis to run tests with different dependency versions
if ENV["GEMFILE_MOD"]
  puts ENV["GEMFILE_MOD"]
  instance_eval(ENV["GEMFILE_MOD"])
else
  group :development do
    gem "chef", git: "https://github.com/chef/chef" # until 13 is released
    gem "ohai", git: "https://github.com/chef/ohai" # until 13 is released
  end
end
