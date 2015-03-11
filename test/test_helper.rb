ENV['RAILS_ENV'] = 'test'

require 'minitest/autorun'
require 'minitest/unit'
require 'minitest/pride'

require File.expand_path('../dummy/config/environment.rb', __FILE__)

require 'database_cleaner'

require 'minifacture'
require 'factories'

require 'recommendable'

DatabaseCleaner.strategy = :transaction
Rails.backtrace_cleaner.remove_silencers!

DatabaseCleaner.start

MiniTest::Unit.after_tests do
  DatabaseCleaner.clean
  Recommendable.redis.flushdb
end
