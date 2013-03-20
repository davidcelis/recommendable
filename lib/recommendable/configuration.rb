require 'redis'

module Recommendable
  class Configuration
    # The ORM you are using. Currently supported: `:activerecord`, `:mongoid`, ':sequel', ':mongo-mapper' and `:datamapper`
    attr_accessor :orm

    # Recommendable's connection to Redis.
    #
    # Default: localhost:6379/0
    attr_accessor :redis

    # A prefix for all keys Recommendable uses.
    #
    # Default: recommendable
    attr_accessor :redis_namespace

    # Whether or not to automatically enqueue users to have their recommendations
    # refreshed after they like/dislike an item.
    #
    # Default: true
    attr_accessor :auto_enqueue

    # The number of nearest neighbors (k-NN) to check when updating
    # recommendations for a user. Set to `nil` if you want to check all
    # neighbors as opposed to a subset of the nearest ones. Set this to a lower
    # number to improve Redis memory usage.
    #
    # Default: nil
    attr_accessor :nearest_neighbors

    # Like kNN, but also uses some number of most dissimilar users when
    # updating recommendations for a user. Because, hey, disagreements are
    # just as important as agreements, right? If `nearest_neighbors` is set to
    # `nil`, this configuration is ignored. Set this to a lower number
    # to improve Redis memory usage.
    #
    # Default: nil
    attr_accessor :furthest_neighbors

    # The number of recommendations to store per user. Set this to a lower
    # number to improve Redis memory usage.
    #
    # Default: 100
    attr_accessor :recommendations_to_store

    attr_accessor :ratable_classes, :user_class

    # Default values
    def initialize
      @redis                    = Redis.new
      @redis_namespace          = :recommendable
      @auto_enqueue             = true
      @ratable_classes          = []
      @nearest_neighbors        = nil
      @furthest_neihbors        = nil
      @recommendations_to_store = 100
    end

    def queue_name
      warn "Recommendable.config.queue_name has been deprecated. Jobs will always be placed in a queue named 'recommendable'."
    end

    def queue_name=(queue_name)
      warn "Recommendable.config.queue_name has been deprecated. Jobs will always be placed in a queue named 'recommendable'."
    end
  end

  class << self
    def configure
      @config ||= Configuration.new
      yield @config
    end

    def config
      @config ||= Configuration.new
    end
  end
end
