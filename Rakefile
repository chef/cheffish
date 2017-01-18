require "bundler"
require "rubygems"
require "rubygems/package_task"
require "rdoc/task"
require "rspec/core/rake_task"

Bundler::GemHelper.install_tasks

task :default => :spec

desc "Run specs"
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = "spec/**/*_spec.rb"
end

gem_spec = eval(File.read("cheffish.gemspec"))

RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = "rdoc"
  rdoc.title = "cheffish #{gem_spec.version}"
  rdoc.rdoc_files.include("README*")
  rdoc.rdoc_files.include("lib/**/*.rb")
end

begin
  require "github_changelog_generator/task"

  GitHubChangelogGenerator::RakeTask.new :changelog do |config|
    require "cheffish/version"
    config.future_release = Cheffish::VERSION
    config.enhancement_labels = "enhancement,Enhancement,Improvement,New Feature,Feature".split(",")
    config.bug_labels = "bug,Bug,Upstream Bug".split(",")
    config.exclude_labels = "duplicate,question,invalid,wontfix,no_changelog,Exclude From Changelog,Question,Discussion".split(",")
    config.max_issues = 0
    config.add_issues_wo_labels = false
  end
rescue LoadError
end

begin
  require "chefstyle"
  require "rubocop/rake_task"
  RuboCop::RakeTask.new(:style) do |task|
    task.options += ["--display-cop-names", "--no-color"]
  end
rescue LoadError
  puts "chefstyle/rubocop is not available."
end
