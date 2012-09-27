require "redis"

Recommendable.configure do |config|
  # Recommendable requires a connection to a running redis-server. Create a new
  # instance based on a host/port or UNIX socket, or pass in an existing client.
  config.redis = Redis.new(:host => 'localhost', :port => 6379)

  # Tell Recommendable how long to wait until unnecessary keys are expired.
  # These keys point to sets that Recommendable uses internally; expiration is
  # to avoid a set being destroyed while another background worker is using it.
  # You should set this value to how long it takes for a worker process to complete.
  # Set to false if you do not wish to expire these keys. Set to :destroy if they
  # can immediately be torn down (you do not have concurrent workers)
  config.expire_keys_in = 1.hour

  # Configure the name of your Sidekiq or Resque queue
  config.queue_name = :recommendable

  # Automatically enqueue users to have their recommendations refreshed after
  # liking/disliking an object. To manually do this, you can use
  # Recommendable.enqueue(user_id)
  config.auto_enqueue = true
end
