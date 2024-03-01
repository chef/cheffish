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
    # chef 17 is on 3.0
    # chef 18 is on 3.1
    case RUBY_VERSION
    when /^3\.0/
      gem "chef", "~> 17.0"
      gem "ohai", "~> 17.0"
    when /^3\.1/
      gem "chef", "~> 18.0"
      gem "ohai", "~> 18.0"
    else
      # go with the latest, unbounded
      gem "chef"
      gem "ohai"
    end
  end
end
