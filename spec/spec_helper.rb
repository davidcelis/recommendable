# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"

require 'minitest/benchmark' if ENV["BENCH"]
require 'minitest/autorun'
require 'minitest/pride'

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

class MiniTest::Spec
  include ActiveSupport::Testing::SetupAndTeardown
  include ActiveRecord::TestFixtures

  alias :method_name :__name__ if defined? :__name__
  self.fixture_path = File.join( Rails.root, 'test', 'fixtures' )
end

# Select the Redis test database
Recommendable.redis.select "15"