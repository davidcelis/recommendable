require 'recommendable'
require 'redis'

Recommendable.configure do |config|
  config.redis = Redis.new(:host => 'localhost', :port => 6379, :db => 15)
end
