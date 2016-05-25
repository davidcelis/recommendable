module Recommendable
  module Rater
    module Scorer
      # Like an object. This will remove the item from a user's set of dislikes,
      # or hidden items.
      #
      # @param [Object] obj the object to be scored
      # @return true if object was scored successfully
      # @raise [ArgumentError] if the passed object was not declared ratable
      def score(obj, score = 1)
        raise(ArgumentError, 'Object has not been declared ratable.') unless obj.respond_to?(:recommendable?) && obj.recommendable?

        if obj.id == nil
          Bugsnag.notify(RuntimeError.new("Rater#score called with nil id type: #{obj.class}, self.id: #{id}"))
          Rails.logger.warn "Rater#score called with nil id type: #{obj.class}, self.id: #{id}"
          Rails.logger.warn caller.join("\n")
        end

        run_hook(:before_score, obj)
        Recommendable.redis.zincrby(Recommendable::Helpers::RedisKeyMapper.scored_set_for(obj.class, id), score, obj.id)
        Recommendable.redis.sadd(Recommendable::Helpers::RedisKeyMapper.scored_by_set_for(obj.class, obj.id), id)
        run_hook(:after_score, obj)

        true
      end

      # Check whether the user has scored an object.
      #
      # @param [Object] obj the object in question
      # @return true if the user has scored obj, false if not
      def scores?(obj)
        Recommendable.redis.zscore(Recommendable::Helpers::RedisKeyMapper.scored_set_for(obj.class, id), obj.id).present?
      end

      # Unlike an object. This removes the object from a user's set of likes.
      #
      # @param [Object] obj the object to be unscored
      # @return true if the object was scored successfully, nil if the object wasn't already scored
      def unscore(obj)
        return unless scores?(obj)

        run_hook(:before_unscore, obj)
        Recommendable.redis.zrem(Recommendable::Helpers::RedisKeyMapper.scored_set_for(obj.class, id), obj.id)
        Recommendable.redis.srem(Recommendable::Helpers::RedisKeyMapper.scored_by_set_for(obj.class, obj.id), id)
        run_hook(:after_unscore, obj)

        true
      end

      # Retrieve an array of objects the user has scored
      #
      # @return [Array] an array of records
      def scores
        Recommendable.config.ratable_classes.map { |klass| scored_for(klass) }.flatten
      end

      # Retrieve an array of objects both this user and another user have scored
      #
      # @return [Array] an array of records
      def scores_in_common_with(user)
        Recommendable.config.ratable_classes.map { |klass| scored_in_common_with(klass, user) }.flatten
      end

      # Get the number of items the user has scored
      #
      # @return [Fixnum] the number of scored items
      def scores_count
        Recommendable.config.ratable_classes.inject(0) do |sum, klass|
          sum + scored_count_for(klass)
        end
      end

      private

      # Fetch IDs for objects belonging to a passed class that the user has scored
      #
      # @param [String, Symbol, Class] the class for which you want IDs
      # @return [Array] an array of IDs
      # @private
      def scored_ids_for(klass)
        ids = Recommendable.redis.zrange(Recommendable::Helpers::RedisKeyMapper.scored_set_for(klass, id), 0, -1)
        ids.map!(&:to_i) if [:active_record, :data_mapper, :sequel].include?(Recommendable.config.orm)
        ids
      end

      # Fetch records belonging to a passed class that the user has scored
      #
      # @param [String, Symbol, Class] the class for which you want scored records
      # @return [Array] an array of scored records
      # @private
      def scored_for(klass)
        Recommendable.query(klass, scored_ids_for(klass))
      end

      # Get the number of items belonging to a passed class that the user has scored
      #
      # @param [String, Symbol, Class] the class for which you want a count of likes
      # @return [Fixnum] the number of likes
      # @private
      def scored_count_for(klass)
        Recommendable.redis.zcard(Recommendable::Helpers::RedisKeyMapper.scored_set_for(klass, id))
      end

      # Get a list of records that both this user and a passed user have scored
      #
      # @param [User] the other user
      # @param [String, Symbol, Class] the class of common scored items
      # @return [Array] an array of records both users have scored
      # @private
      def scored_in_common_with(klass, user)
        Recommendable.query(klass, scored_ids_in_common_with(klass, user))
      end

      # Get a list of IDs for records that both this user and a passed user have
      # scored
      #
      # @param [User, Fixnum] the other user (or its ID)
      # @param [String, Symbol, Class] the class of common scored items
      # @return [Array] an array of IDs for records that both users have scored
      # @private
      def scored_ids_in_common_with(klass, user_id)
        user_id = user_id.id if user_id.is_a?(Recommendable.config.user_class)
        scored_set = Recommendable::Helpers::RedisKeyMapper.scored_set_for(klass, id)
        other_scored_set = Recommendable::Helpers::RedisKeyMapper.scored_set_for(klass, user_id)
        temp_set = Recommendable::Helpers::RedisKeyMapper.temp_set_for(klass, id)
        Recommendable.redis.zinterstore(
          temp_set,
          [scored_set, other_scored_set]
        )
        ids = Recommendable.redis.zrange(temp_set, 0, -1)
        Recommendable.redis.del(temp_set)
        ids.map!(&:to_i) if [:active_record, :data_mapper, :sequel].include?(Recommendable.config.orm)
        ids
      end
    end
  end
end
