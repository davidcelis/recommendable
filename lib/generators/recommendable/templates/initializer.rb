require "redis"
require "resque"
require "resque-loner"

# Recommendable requires a connection to a running redis-server. Either create
# a new instance based on a host/port or UNIX socket, or pass in an existing
# Redis client instance.
<% if options.redis_socket %># <% end %>Recommendable.redis = Redis.new(:host => "<%= redis_host %>", :port => <%= redis_port %>)

# Connect to Redis via a UNIX socket instead
<% unless options.redis_socket %># <% end %>Recommendable.redis = Redis.new(:sock => "<%= options.redis_socket %>")

# Resque also needs a connection to Redis. If you are currently initializing
# Resque somewhere else, leave this commented out. Otherwise, let it use the
# same Redis connection as Recommendable. If redis is running on localhost:6379,
# You can leave this commented out.
# Resque.redis = Recommendable.redis

# Tell Redis which database to use (usually between 0 and 15). The default of 0
# is most likely okay unless you have another application using that database.
# Recommendable.redis.select "0"
