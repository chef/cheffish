source "https://rubygems.org"

gemspec

group :development do
  gem "cookstyle", "~> 7.32.8"
  gem "rake"
  gem "rspec", "~> 3.0"
end

# Allow Travis to run tests with different dependency versions
if ENV["GEMFILE_MOD"]
  puts ENV["GEMFILE_MOD"]
  instance_eval(ENV["GEMFILE_MOD"])
else
  group :development do
    # temporarily we only support building against main
    if RUBY_VERSION =~ /^3\.1/
      gem "date", "= 3.2.2"
      gem "racc", "= 1.6.0"
      gem "bigdecimal", "= 3.1.1"
      gem "json", "= 2.6.1"
      gem "chef", "~> 18.0"
      gem "ohai", "~> 18.0"
    else
      gem "chef", "~> 17.0"
      gem "ohai", "~> 17.0"
    end
  end
end
