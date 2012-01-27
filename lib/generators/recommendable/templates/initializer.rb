require "redis"

# What class will be liking/disliking objects and receiving recommendations?
Recommendable.user_class = "<%= user_class %>"

# If a user ignores a recommendation, how long in seconds until that ignore
# expires? The default for this is option three months.
Recommendable.expiration_ttl = 60 * 60 * 24 * 30 * 3

# Recommendable requires a connection to a running redis-server. Either create
# a new instance based on a host/port or UNIX socket, or pass in an existing
# Redis client instance.
<% if options.redis_socket %># <% end %>Recommendable.redis = Redis.new(:host => "<%= redis_host %>", :port => <%= redis_port %>)

# Connect to Redis via a UNIX socket instead
<% unless options.redis_socket %># <% end %>Recommendable.redis = Redis.new(:sock => "<%= options.redis_socket %>")
