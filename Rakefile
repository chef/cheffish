require "bundler/gem_tasks"

begin
  require "rspec/core/rake_task"

  RSpec::Core::RakeTask.new do |t|
    t.pattern = "spec/**/*_spec.rb"
  end
rescue LoadError
  desc "rspec is not installed, this task is disabled"
  task :spec do
    abort "rspec is not installed. bundle install first to make sure all dependencies are installed."
  end
end

def require_gem(gem_name)
  require gem_name
rescue LoadError
  puts "#{gem_name} gem is not installed. Please run 'bundle install' first to make sure all dependencies are installed."
  exit 1
end

desc "Check Linting and code style."
task :style do
  require_gem "rubocop/rake_task"
  require_gem "cookstyle/chefstyle"

  if RbConfig::CONFIG["host_os"] =~ /mswin|mingw|cygwin/
    # Windows-specific command, rubocop erroneously reports the CRLF in each file which is removed when your PR is uploaeded to GitHub.
    # This is a workaround to ignore the CRLF from the files before running cookstyle.
    sh "cookstyle --chefstyle -c .rubocop.yml --except Layout/EndOfLine"
  else
    sh "cookstyle --chefstyle -c .rubocop.yml"
  end
end

begin
  require "yard"
  YARD::Rake::YardocTask.new(:docs)
rescue LoadError
  puts "yard is not available. bundle install first to make sure all dependencies are installed."
end

task :console do
  require "irb"
  require "irb/completion"
  require "cheffish"
  ARGV.clear
  IRB.start
end

task default: %i{spec style}
