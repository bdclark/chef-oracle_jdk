require 'bundler/setup'

# Style tests - Rubocop and Foodcritic
namespace :style do
  require 'rubocop/rake_task'
  desc 'Run rubocop for Ruby style checks'
  RuboCop::RakeTask.new(:ruby)

  require 'foodcritic'
  desc 'Run foodcritic for Chef style checks'
  FoodCritic::Rake::LintTask.new(:chef)
end

desc 'Run all style checks'
task style: ['style:chef', 'style:ruby']

# Rspec and ChefSpec
require 'rspec/core/rake_task'
desc 'Run ChefSpec examples with rspec documentation'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = '--format documentation --color'
end

desc 'Run style and unit tests'
task default: %w(style spec)

# Integration tests. Kitchen.ci
namespace :integration do
  desc 'Run Test Kitchen with Vagrant'
  task :vagrant do
    Kitchen.logger = Kitchen.default_file_logger
    Kitchen::Config.new.instances.each do |instance|
      instance.test(:always)
    end
  end

  desc 'Run Test Kitchen with cloud plugins'
  task :cloud do
    run_kitchen = true
    if ENV['TRAVIS'] == 'true' && ENV['TRAVIS_PULL_REQUEST'] != 'false'
      run_kitchen = false
    end

    if run_kitchen
      Kitchen.logger = Kitchen.default_file_logger
      @loader =
        Kitchen::Loader::YAML.new(project_config: './.kitchen.cloud.yml')
      config = Kitchen::Config.new(loader: @loader)
      config.instances.each do |instance|
        instance.test(:always)
      end
    end
  end
end
