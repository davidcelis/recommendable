require "coveralls"
Coveralls.wear! do
  add_filter "/test/"
end

ENV["RAILS_ENV"] = "test"
require File.expand_path("../dummy/config/environment.rb", __FILE__)
require "rails/test_help"

require "minitest/unit"
require "minitest/pride"
require "minitest/autorun"

require "database_cleaner"

require "miniskirt"
require "factories"

require "recommendable"

DatabaseCleaner.strategy = :transaction
Rails.backtrace_cleaner.remove_silencers!

DatabaseCleaner.start

MiniTest::Unit.after_tests do
  DatabaseCleaner.clean
  Recommendable.redis.flushdb
end
