module Recommendable
  module Rater
    module Bookmarker
      # Bookmark an object. This is not possible if the object is hidden.
      #
      # @param [Object] obj the object to be bookmarked
      # @return true if object was bookmarked successfully
      # @raise [ArgumentError] if the passed object was not declared ratable
      def bookmark(obj)
        raise(ArgumentError, 'Object has not been declared ratable.') unless obj.respond_to?(:recommendable?) && obj.recommendable?
        return if hides?(obj) || bookmarks?(obj)

        run_hook(:before_bookmark, obj)
        Recommendable.redis.sadd(Recommendable::Helpers::RedisKeyMapper.bookmarked_set_for(obj.class, id), obj.id)
        run_hook(:after_bookmark, obj)

        true
      end

      # Check whether the user has bookmarked an object.
      #
      # @param [Object] obj the object in question
      # @return true if the user has bookmarked obj, false if not
      def bookmarks?(obj)
        Recommendable.redis.sismember(Recommendable::Helpers::RedisKeyMapper.bookmarked_set_for(obj.class, id), obj.id)
      end

      # Unbookmark an object. This removes the object from a user's set of bookmarks.
      #
      # @param [Object] obj the object to be unbookmarked
      # @return true if the object was bookmarked successfully, nil if the object wasn't already bookmarked
      def unbookmark(obj)
        return unless bookmarks?(obj)

        run_hook(:before_unbookmark, obj)
        Recommendable.redis.srem(Recommendable::Helpers::RedisKeyMapper.bookmarked_set_for(obj.class, id), obj.id)
        run_hook(:after_unbookmark, obj)

        true
      end

      # Retrieve an array of objects the user has bookmarked
      #
      # @return [Array] an array of records
      def bookmarks
        Recommendable.config.ratable_classes.map { |klass| bookmarked_for(klass) }.flatten
      end

      # Retrieve an array of objects both this user and another user have bookmarked
      #
      # @return [Array] an array of records
      def bookmarks_in_common_with(user)
        Recommendable.config.ratable_classes.map { |klass| bookmarked_in_common_with(klass, user) }.flatten
      end

      # Get the number of items the user has bookmarked
      #
      # @return [Fixnum] the number of bookmarked items
      def bookmarks_count
        Recommendable.config.ratable_classes.inject(0) do |sum, klass|
          sum + bookmarked_count_for(klass)
        end
      end

      private

      # Fetch IDs for objects belonging to a passed class that the user has bookmarked
      #
      # @param [String, Symbol, Class] the class for which you want IDs
      # @return [Array] an array of IDs
      # @private
      def bookmarked_ids_for(klass)
        ids = Recommendable.redis.smembers(Recommendable::Helpers::RedisKeyMapper.bookmarked_set_for(klass, id))
        ids.map!(&:to_i) if [:active_record, :data_mapper, :sequel].include?(Recommendable.config.orm)
        ids
      end

      # Fetch records belonging to a passed class that the user has bookmarked
      #
      # @param [String, Symbol, Class] the class for which you want bookmarked records
      # @return [Array] an array of bookmarked records
      # @private
      def bookmarked_for(klass)
        Recommendable.query(klass, bookmarked_ids_for(klass))
      end

      # Get the number of items belonging to a passed class that the user has bookmarked
      #
      # @param [String, Symbol, Class] the class for which you want a count of bookmarks
      # @return [Fixnum] the number of bookmarks
      # @private
      def bookmarked_count_for(klass)
        Recommendable.redis.scard(Recommendable::Helpers::RedisKeyMapper.bookmarked_set_for(klass, id))
      end

      # Get a list of records that both this user and a passed user have
      # bookmarked
      #
      # @param [User] the other user
      # @param [String, Symbol, Class] the class of common bookmarked items
      # @return [Array] an array of records both users have bookmarked
      # @private
      def bookmarked_in_common_with(klass, user)
        Recommendable.query(klass, bookmarked_ids_in_common_with(klass, user))
      end

      # Get a list of IDs for records that both this user and a passed user have
      # bookmarked
      #
      # @param [User] the other user
      # @param [String, Symbol, Class] the class of common bookmarked items
      # @return [Array] an array of IDs for records that both users have bookmarked
      # @private
      def bookmarked_ids_in_common_with(klass, user_id)
        user_id = user_id.id if user_id.is_a?(Recommendable.config.user_class)
        Recommendable.redis.sinter(Recommendable::Helpers::RedisKeyMapper.bookmarked_set_for(klass, id), Recommendable::Helpers::RedisKeyMapper.bookmarked_set_for(klass, user_id))
      end
    end
  end
end
