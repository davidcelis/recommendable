require 'redis'

module Recommendable
  class Configuration
    # The ORM you are using. Currently supported: `:activerecord`, `:mongoid`, and `:datamapper`
    attr_accessor :orm

    # Recommendable's connection to Redis
    attr_accessor :redis

    # A prefix for all keys Recommendable uses
    attr_accessor :redis_namespace

    # Whether or not to automatically enqueue users to have their recommendations
    # refreshed after they like/dislike an item
    attr_accessor :auto_enqueue

    # The name of the queue that background jobs will be placed in
    attr_accessor :queue_name

    # The number of nearest neighbors (k-NN) to check when updating
    # recommendations for a user. Set to `nil` if you want to check all
    # neighbors as opposed to a subset of the nearest ones.
    attr_accessor :nearest_neighbors

    attr_accessor :ratable_classes, :user_class

    # Default values
    def initialize
      @redis             = Redis.new
      @redis_namespace   = :recommendable
      @auto_enqueue      = true
      @queue_name        = :recommendable
      @ratable_classes   = []
      @nearest_neighbors = nil
    end
  end

  class << self
    attr_accessor :config

    def configure
      @config ||= Configuration.new
      yield @config
    end
  end
end
