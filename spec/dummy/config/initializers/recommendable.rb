require "redis"
require "sidekiq"

Recommendable.redis = Redis.new(:host => "localhost", :port => 6379)
Recommendable.redis.select("15")
