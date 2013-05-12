#!/usr/bin/env rake
require "bundler/gem_tasks"
require "rake/clean"
require "rake/testtask"
require "yard"

begin
  Bundler.setup :default, :development
  Bundler::GemHelper.install_tasks
rescue Bundler::BundlerError => error
  $stderr.puts error.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit error.status_code
end

desc "Run all of the tests"
Rake::TestTask.new(:test) do |config|
  config.libs << "test"
  config.pattern = "test/**/*_test.rb"
  t.verbose = true
end

desc "Generate all of the docs"
YARD::Rake::YardocTask.new do |config|
  config.files = Dir["lib/**/*.rb"]
end
desc "Default: run tests and generate docs"
task :default => [ :test, :yard ]

