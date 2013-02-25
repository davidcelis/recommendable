require 'recommendable/ratable/likable'
require 'recommendable/ratable/dislikable'

module Recommendable
  module Ratable
    extend ActiveSupport::Concern

    def recommendable?() self.class.recommendable? end

    module ClassMethods
      def make_recommendable!
        Recommendable.configure { |config| config.ratable_classes << self }

        class_eval do
          include Likable
          include Dislikable
          
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
            liked_by_count > 0 || disliked_by_count > 0
          end

          # Query for the top-N items sorted by score
          #
          # @param [Fixnum] count the number of items to fetch (defaults to 1)
          # @return [Array] the top items belonging to this class, sorted by score
          def self.top(count = 1)
            score_set = Recommendable::Helpers::RedisKeyMapper.score_set_for(self)
            ids = Recommendable.redis.zrevrange(score_set, 0, count - 1)

            Recommendable.query(self, ids).sort_by { |item| ids.index(item.id.to_s) }
          end

          private

          # Completely removes this item from redis. Called from a before_destroy hook.
          # @private
          def remove_from_recommendable!
            # Remove this item from the score zset
            Recommendable.redis.zrem(Recommendable::Helpers::RedisKeyMapper.score_set_for(self.class), id)

            # Remove this item's liked_by/disliked_by sets
            %w[liked_by disliked_by].each do |action|
              set = Recommendable::Helpers::RedisKeyMapper.send("#{action}_set_for", self.class, id)
              Recommendable.redis.del(set)
            end

            # Remove this item from any user's like/dislike/hidden/bookmark sets
            %w[liked disliked hidden bookmarked].each do |action|
              set = Recommendable::Helpers::RedisKeyMapper.send("#{action}_set_for", self.class, id)
              Recommendable.redis.keys(set).each do |set|
                Recommendable.redis.srem(set, id)
              end
            end

            # Remove this item from any user's recommendation zset
            Recommendable.redis.keys(Recommendable::Helpers::RedisKeyMapper.recommended_set_for(self.class, '*')).each do |zset|
              Recommendable.redis.zrem(zset, id)
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
