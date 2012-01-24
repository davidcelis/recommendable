require "recommendable/engine"
require "recommendable/rater"

module Recommendable
  mattr_accessor :user_class, :redis, :redis_host, :redis_port, :redis_socket
  
  class << self
    def user_class
      @@user_class.constantize
    end
    
    def redis
      if @@redis_socket
        @@redis ||= Redis.new(:path => @@redis_socket)
      else
        @@redis ||= Redis.new(@@redis_host, @@redis_port)
      end
    end
  end
end