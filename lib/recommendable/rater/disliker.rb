module Recommendable
  module Rater
    module Disliker
      # Dislike an object. This will remove the item from a user's set of likes
      # or hidden items
      #
      # @param [Object] obj the object to be disliked
      # @return true if object was disliked successfully
      # @raise [ArgumentError] if the passed object was not declared ratable
      def dislike(obj)
        raise(ArgumentError, 'Object has not been declared ratable.') unless obj.respond_to?(:recommendable?) && obj.recommendable?
        return if dislikes?(obj)

        run_hook(:before_dislike, obj)
        Recommendable.redis.sadd(Recommendable::Helpers::RedisKeyMapper.disliked_set_for(obj.class, id), obj.id)
        Recommendable.redis.sadd(Recommendable::Helpers::RedisKeyMapper.disliked_by_set_for(obj.class, obj.id), id)
        run_hook(:after_dislike, obj)

        true
      end

      # Check whether the user has disliked an object.
      #
      # @param [Object] obj the object in question
      # @return true if the user has disliked obj, false if not
      def dislikes?(obj)
        Recommendable.redis.sismember(Recommendable::Helpers::RedisKeyMapper.disliked_set_for(obj.class, id), obj.id)
      end

      # Undislike an object. This removes the object from a user's set of dislikes.
      #
      # @param [Object] obj the object to be undisliked
      # @return true if the object was disliked successfully, nil if the object wasn't already disliked
      def undislike(obj)
        return unless dislikes?(obj)

        run_hook(:before_undislike, obj)
        Recommendable.redis.srem(Recommendable::Helpers::RedisKeyMapper.disliked_set_for(obj.class, id), obj.id)
        Recommendable.redis.srem(Recommendable::Helpers::RedisKeyMapper.disliked_by_set_for(obj.class, obj.id), id)
        run_hook(:after_undislike, obj)

        true
      end

      # Retrieve an array of objects the user has disliked
      #
      # @return [Array] an array of records
      def dislikes
        Recommendable.config.ratable_classes.map { |klass| disliked_for(klass) }.flatten
      end

      # Retrieve an array of objects both this user and another user have disliked
      #
      # @return [Array] an array of records
      def dislikes_in_common_with(user)
        Recommendable.config.ratable_classes.map { |klass| disliked_in_common_with(klass, user) }.flatten
      end

      # Get the number of items the user has disliked
      #
      # @return [Fixnum] the number of disliked items
      def dislikes_count
        Recommendable.config.ratable_classes.inject(0) do |sum, klass|
          sum + disliked_count_for(klass)
        end
      end

      private

      # Fetch IDs for objects belonging to a passed class that the user has disliked
      #
      # @param [String, Symbol, Class] the class for which you want IDs
      # @return [Array] an array of IDs
      # @private
      def disliked_ids_for(klass)
        ids = Recommendable.redis.smembers(Recommendable::Helpers::RedisKeyMapper.disliked_set_for(klass, id))
        ids.map!(&:to_i) if [:active_record, :data_mapper, :sequel].include?(Recommendable.config.orm)
        ids
      end

      # Fetch records belonging to a passed class that the user has disliked
      #
      # @param [String, Symbol, Class] the class for which you want disliked records
      # @return [Array] an array of disliked records
      # @private
      def disliked_for(klass)
        Recommendable.query(klass, disliked_ids_for(klass))
      end

      # Get the number of items belonging to a passed class that the user has disliked
      #
      # @param [String, Symbol, Class] the class for which you want a count of dislikes
      # @return [Fixnum] the number of dislikes
      # @private
      def disliked_count_for(klass)
        Recommendable.redis.scard(Recommendable::Helpers::RedisKeyMapper.disliked_set_for(klass, id))
      end

      # Get a list of records that both this user and a passed user have disliked
      #
      # @param [User] the other user
      # @param [String, Symbol, Class] the class of common disliked items
      # @return [Array] an array of records both users have disliked
      # @private
      def disliked_in_common_with(klass, user)
        Recommendable.query(klass, disliked_ids_in_common_with(klass, user))
      end

      # Get a list of IDs for records that both this user and a passed user have
      # disliked
      #
      # @param [User, Fixnum] the other user (or its ID)
      # @param [String, Symbol, Class] the class of common disliked items
      # @return [Array] an array of IDs for records that both users have disliked
      # @private
      def disliked_ids_in_common_with(klass, user_id)
        user_id = user_id.id if user_id.is_a?(Recommendable.config.user_class)
        Recommendable.redis.sinter(Recommendable::Helpers::RedisKeyMapper.disliked_set_for(klass, id), Recommendable::Helpers::RedisKeyMapper.disliked_set_for(klass, user_id))
      end
    end
  end
end
