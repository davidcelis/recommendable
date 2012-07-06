require "redis"

# What class will be liking/disliking objects and receiving recommendations?
Recommendable.user_class = "User"

# Recommendable requires a connection to a running redis-server. Either create
# a new instance based on a host/port or UNIX socket, or pass in an existing
# Redis client instance.
Recommendable.redis = Redis.new(:host => "localhost", :port => 6379)

# Connect to Redis via a UNIX socket instead
# Recommendable.redis = Redis.new(:sock => "")

Recommendable.redis.select("15")
