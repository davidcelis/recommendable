require "recommendable/engine"
require "recommendable/rater"

module Recommendable
  mattr_accessor :user_class, :redis, :redis_host, :redis_port
  
  class << self
    def user_class
      @@user_class.constantize
    end
    
    def redis
      @@redis ||= Redis.new(@@redis_host, @@redis_port)
    end
  end
end