class App < Configurable # :nodoc:
  # Settings in config/app/* take precedence over those specified here.
  config.name = Rails.application.class.parent.name

  # Connect to the Redis database.
  config.redis = Redis.new(host: '127.0.0.1', port: 6379)
end
