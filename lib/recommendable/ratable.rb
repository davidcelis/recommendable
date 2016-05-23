require 'recommendable/ratable/scoreable'

module Recommendable
  module Ratable
    extend ActiveSupport::Concern

    def recommendable?() self.class.recommendable? end

    module ClassMethods
      def make_recommendable!
        Recommendable.configure do |config|
          config.ratable_classes << self
        end

        class_eval do
          include Scoreable

          case
          when defined?(Sequel::Model) && ancestors.include?(Sequel::Model)
            def before_destroy() super and remove_from_recommendable! end
          when defined?(ActiveRecord::Base)            && ancestors.include?(ActiveRecord::Base),
               defined?(Mongoid::Document)             && ancestors.include?(Mongoid::Document),
               defined?(MongoMapper::Document)         && ancestors.include?(MongoMapper::Document),
               defined?(MongoMapper::EmbeddedDocument) && ancestors.include?(MongoMapper::EmbeddedDocument)
            before_destroy :remove_from_recommendable!
          when defined?(DataMapper::Resource) && ancestors.include?(DataMapper::Resource)
            before :destroy, :remove_from_recommendable!
          else
            warn "Model #{self} is not using a supported ORM. You must handle removal from Redis manually when destroying instances."
          end

          # Whether or not items belonging to this class can be recommended.
          #
          # @return true if a user class `recommends :this`
          def self.recommendable?() true end

          # Check to see if anybody has rated (liked or disliked) this object
          #
          # @return true if anybody has liked/disliked this
          def rated?
            scored_by_count > 0
          end

          # Query for the top-N items sorted by score
          #
          # @param [Fixnum] count the number of items to fetch (defaults to 1)
          # @return [Array] the top items belonging to this class, sorted by score
          def self.top(options = {})
            if options.is_a?(Integer)
              options = { :count => options}
              warn "[DEPRECATION] Recommenable::Ratable.top now takes an options hash. Please call `.top(count: #{options[:count]})` instead of just `.top(#{options[:count]})`"
            end
            options.reverse_merge!(:count => 1, :offset => 0)
            score_set = Recommendable::Helpers::RedisKeyMapper.score_set_for(self)
            ids = Recommendable.redis.zrevrange(score_set, options[:offset], options[:offset] + options[:count] - 1)

            return [] if ids.empty?
            order = ids.map { |id| "id = %d DESC" }.join(', ')
            order = self.send(:sanitize_sql_for_assignment, [order, *ids])
            Recommendable.query(self, ids).order(order)
          end

          # Returns the class that has been explicitly been made ratable, whether it is this
          # class or a superclass. This allows a ratable class and all of its subclasses to be
          # considered the same type of ratable and give recommendations from the base class
          # or any of the subclasses.
          def self.ratable_class
            ancestors.find { |klass| Recommendable.config.ratable_classes.include?(klass) }
          end

          private

          # Completely removes this item from redis. Called from a before_destroy hook.
          # @private
          def remove_from_recommendable!
            sets  = [] # SREM needed
            zsets = [] # ZREM needed
            keys  = [] # DEL  needed
            # Remove this item from the score zset
            zsets << Recommendable::Helpers::RedisKeyMapper.score_set_for(self.class)

            # Remove this item's liked_by/disliked_by sets
            keys << Recommendable::Helpers::RedisKeyMapper.scored_by_set_for(self.class, id)

            # Remove this item from any user's like/dislike/hidden/bookmark sets
            %w[scored bookmarked].each do |action|
              sets += Recommendable.redis.keys(Recommendable::Helpers::RedisKeyMapper.send("#{action}_set_for", self.class, '*'))
            end

            # Remove this item from any user's recommendation zset
            zsets += Recommendable.redis.keys(Recommendable::Helpers::RedisKeyMapper.recommended_set_for(self.class, '*'))

            Recommendable.redis.pipelined do |redis|
              sets.each { |set| redis.srem(set, id) }
              zsets.each { |zset| redis.zrem(zset, id) }
              redis.del(*keys)
            end
          end
        end
      end

      # Whether or not items belonging to this class can be recommended.
      #
      # @return true if a user class `recommends :this`
      def recommendable?() false end
    end
  end
end
