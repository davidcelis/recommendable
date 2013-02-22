module Recommendable
  module Rater
    module Recommender
      # Get a list of raters that have been found to be the most similar to
      # self. They are sorted by the calculated similarity value.
      #
      # @param [Fixnum] count the number of users to return (defaults to 10)
      # @return [Array] An array of instances of your user class
      def similar_raters(count = 10)
        ids = Recommendable.redis.zrevrange(Recommendable::Helpers::RedisKeyMapper.similarity_set_for(id), 0, count - 1)
        Recommendable.query(self.class, ids).sort_by { |user| ids.index(user.id.to_s) }
      end

      private

      # Fetch a list of recommendations for a passed class.
      #
      # @param [String, Symbol, Class] klass the class from which to get recommendations
      # @param [Fixnum] count the number of recommendations to fetch (defaults to 10)
      # @return [Array] a list of things this person's gonna love
      def recommended_for(klass, count = 10)
        recommended_set = Recommendable::Helpers::RedisKeyMapper.recommended_set_for(klass, self.id)
        return Recommendable.query(klass, []) unless rated_anything? && Recommendable.redis.zcard(recommended_set) > 0

        ids = Recommendable.redis.zrevrange(recommended_set, 0, count - 1)
        Recommendable.query(klass, ids)
      end

      # Removes an item from a user's set of recommendations
      # @private
      def unrecommend(obj)
        Recommendable.redis.zrem(Recommendable::Helpers::RedisKeyMapper.recommended_set_for(obj.class, id), obj.id)
        true
      end

      # Removes a user from Recommendable. Called internally on a before_destroy hook.
      # @private
      def remove_from_recommendable!
        # Remove this user's similarity ZSET
        Recommendable.redis.del(Recommendable::Helpers::RedisKeyMapper.similarity_set_for(id))

        # Remove from other users' similarity ZSETs
        Recommendable.redis.keys(Recommendable::Helpers::RedisKeyMapper.similarity_set_for('*')).each do |zset|
          Recommendable.redis.zrem(zset, id)
        end

        # For each ratable class...
        Recommendable.config.ratable_classes.each do |klass|
          # Remove this user from any class member's liked_by/disliked_by sets
          Recommendable.redis.keys(Recommendable::Helpers::RedisKeyMapper.liked_by_set_for(klass, '*')).each do |set|
            Recommendable.redis.srem(set, id)
          end

          Recommendable.redis.keys(Recommendable::Helpers::RedisKeyMapper.disliked_by_set_for(klass, '*')).each do |set|
            Recommendable.redis.srem(set, id)
          end
          # Remove this user from any class member's bookmarked_by sets
          Recommendable.redis.keys(Recommendable::Helpers::RedisKeyMapper.bookmarked_by_set_for(klass, '*')).each do |set|
            Recommendable.redis.srem(set, id)
          end

          # Remove this user's liked/disliked/hidden/bookmarked/recommended sets for the class
          Recommendable.redis.del(Recommendable::Helpers::RedisKeyMapper.liked_set_for(klass, id))
          Recommendable.redis.del(Recommendable::Helpers::RedisKeyMapper.disliked_set_for(klass, id))
          Recommendable.redis.del(Recommendable::Helpers::RedisKeyMapper.hidden_set_for(klass, id))
          Recommendable.redis.del(Recommendable::Helpers::RedisKeyMapper.bookmarked_set_for(klass, id))
          Recommendable.redis.del(Recommendable::Helpers::RedisKeyMapper.recommended_set_for(klass, id))
        end
      end
    end
  end
end
