module Recommendable
  module Rater
    module Liker
      # Like an object. This will remove the item from a user's set of dislikes,
      # or hidden items.
      #
      # @param [Object] obj the object to be liked
      # @return true if object was liked successfully
      # @raise [ArgumentError] if the passed object was not declared ratable
      def like(obj)
        raise(ArgumentError, 'Object has not been declared ratable.') unless obj.respond_to?(:recommendable?) && obj.recommendable?
        return if likes?(obj)

        run_hook(:before_like, obj)
        Recommendable.redis.sadd(Recommendable::Helpers::RedisKeyMapper.liked_set_for(obj.class, id), obj.id)
        Recommendable.redis.sadd(Recommendable::Helpers::RedisKeyMapper.liked_by_set_for(obj.class, obj.id), id)
        run_hook(:after_like, obj)

        true
      end

      # Check whether the user has liked an object.
      #
      # @param [Object] obj the object in question
      # @return true if the user has liked obj, false if not
      def likes?(obj)
        Recommendable.redis.sismember(Recommendable::Helpers::RedisKeyMapper.liked_set_for(obj.class, id), obj.id)
      end

      # Unlike an object. This removes the object from a user's set of likes.
      #
      # @param [Object] obj the object to be unliked
      # @return true if the object was liked successfully, nil if the object wasn't already liked
      def unlike(obj)
        return unless likes?(obj)

        run_hook(:before_unlike, obj)
        Recommendable.redis.srem(Recommendable::Helpers::RedisKeyMapper.liked_set_for(obj.class, id), obj.id)
        Recommendable.redis.srem(Recommendable::Helpers::RedisKeyMapper.liked_by_set_for(obj.class, obj.id), id)
        run_hook(:after_unlike, obj)

        true
      end

      # Retrieve an array of objects the user has liked
      #
      # @return [Array] an array of records
      def likes
        Recommendable.config.ratable_classes.map { |klass| liked_for(klass) }.flatten
      end

      # Retrieve an array of objects both this user and another user have liked
      #
      # @return [Array] an array of records
      def likes_in_common_with(user)
        Recommendable.config.ratable_classes.map { |klass| liked_in_common_with(klass, user) }.flatten
      end

      # Get the number of items the user has liked
      #
      # @return [Fixnum] the number of liked items
      def likes_count
        Recommendable.config.ratable_classes.inject(0) do |sum, klass|
          sum + liked_count_for(klass)
        end
      end

      # Fetch IDs for objects belonging to a passed class that the user has liked
      #
      # @param [String, Symbol, Class] the class for which you want IDs
      # @return [Array] an array of IDs
      def liked_ids_for(klass)
        ids = Recommendable.redis.smembers(Recommendable::Helpers::RedisKeyMapper.liked_set_for(klass, id))
        ids.map!(&:to_i) if [:active_record, :data_mapper, :sequel].include?(Recommendable.config.orm)
        ids
      end

      # Fetch records belonging to a passed class that the user has liked
      #
      # @param [String, Symbol, Class] the class for which you want liked records
      # @return [Array] an array of liked records
      def liked_for(klass)
        Recommendable.query(klass, liked_ids_for(klass))
      end

      # Get the number of items belonging to a passed class that the user has liked
      #
      # @param [String, Symbol, Class] the class for which you want a count of likes
      # @return [Fixnum] the number of likes
      def liked_count_for(klass)
        Recommendable.redis.scard(Recommendable::Helpers::RedisKeyMapper.liked_set_for(klass, id))
      end

      # Get a list of records that both this user and a passed user have liked
      #
      # @param [User] the other user
      # @param [String, Symbol, Class] the class of common liked items
      # @return [Array] an array of records both users have liked
      def liked_in_common_with(klass, user)
        Recommendable.query(klass, liked_ids_in_common_with(klass, user))
      end

      # Get a list of IDs for records that both this user and a passed user have
      # liked
      #
      # @param [User, Fixnum] the other user (or its ID)
      # @param [String, Symbol, Class] the class of common liked items
      # @return [Array] an array of IDs for records that both users have liked
      def liked_ids_in_common_with(klass, user_id)
        user_id = user_id.id if user_id.is_a?(Recommendable.config.user_class)
        Recommendable.redis.sinter(Recommendable::Helpers::RedisKeyMapper.liked_set_for(klass, id), Recommendable::Helpers::RedisKeyMapper.liked_set_for(klass, user_id))
      end
    end
  end
end
