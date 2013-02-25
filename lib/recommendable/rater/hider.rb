module Recommendable
  module Rater
    module Hider
      # Hide an object. This action is only possible if the user has not yet
      # rated or bookmarked the object.
      #
      # @param [Object] obj the object to be hidden
      # @return true if object was hidden successfully
      # @raise [ArgumentError] if the passed object was not declared ratable
      def hide(obj)
        raise(ArgumentError, 'Object has not been declared ratable.') unless obj.respond_to?(:recommendable?) && obj.recommendable?
        return if likes?(obj) || dislikes?(obj) || bookmarks?(obj) || hides?(obj)

        run_hook(:before_hide, obj)
        Recommendable.redis.sadd(Recommendable::Helpers::RedisKeyMapper.hidden_set_for(obj.class, id), obj.id)
        run_hook(:after_hide, obj)

        true
      end

      # Check whether the user has hidden an object.
      #
      # @param [Object] obj the object in question
      # @return true if the user has hidden obj, false if not
      def hides?(obj)
        Recommendable.redis.sismember(Recommendable::Helpers::RedisKeyMapper.hidden_set_for(obj.class, id), obj.id)
      end

      # Unhide an object. This removes the object from a user's set of hidden items.
      #
      # @param [Object] obj the object to be made visible
      # @return true if the object was successfully made visible, nil if the object wasn't already hidden
      def unhide(obj)
        return unless hides?(obj)

        run_hook(:before_unhide, obj)
        Recommendable.redis.srem(Recommendable::Helpers::RedisKeyMapper.hidden_set_for(obj.class, id), obj.id)
        run_hook(:after_unhide, obj)

        true
      end

      # Retrieve an array of objects the user has hidden
      #
      # @return [Array] an array of records
      def hiding
        Recommendable.config.ratable_classes.map { |klass| hidden_for(klass) }.flatten
      end

      # Retrieve an array of objects both this user and another user have hidden
      #
      # @return [Array] an array of records
      def hiding_in_common_with(user)
        Recommendable.config.ratable_classes.map { |klass| hidden_in_common_with(klass, user) }.flatten
      end

      # Get the number of items the user has hidden
      #
      # @return [Fixnum] the number of hidden items
      def hidden_count
        Recommendable.config.ratable_classes.inject(0) do |sum, klass|
          sum + hidden_count_for(klass)
        end
      end

      private

      # Fetch IDs for objects belonging to a passed class that the user has hidden
      #
      # @param [String, Symbol, Class] the class for which you want IDs
      # @return [Array] an array of IDs
      # @private
      def hidden_ids_for(klass)
        ids = Recommendable.redis.smembers(Recommendable::Helpers::RedisKeyMapper.hidden_set_for(klass, id))
        ids.map!(&:to_i) if [:active_record, :data_mapper, :sequel].include?(Recommendable.config.orm)
        ids
      end

      # Fetch records belonging to a passed class that the user has hidden
      #
      # @param [String, Symbol, Class] the class for which you want hidden records
      # @return [Array] an array of hidden records
      # @private
      def hidden_for(klass)
        Recommendable.query(klass, hidden_ids_for(klass))
      end

      # Get the number of items belonging to a passed class that the user has hidden
      #
      # @param [String, Symbol, Class] the class for which you want a count of hidden items
      # @return [Fixnum] the number of hidden items
      # @private
      def hidden_count_for(klass)
        Recommendable.redis.scard(Recommendable::Helpers::RedisKeyMapper.hidden_set_for(klass, id))
      end

      # Get a list of records that both this user and a passed user have hidden
      #
      # @param [User] the other user
      # @param [String, Symbol, Class] the class of common hidden items
      # @return [Array] an array of records both users have hidden
      # @private
      def hidden_in_common_with(klass, user)
        Recommendable.query(klass, hidden_ids_in_common_with(klass, user))
      end

      # Get a list of IDs for records that both this user and a passed user have
      # hidden
      #
      # @param [User] the other user
      # @param [String, Symbol, Class] the class of common hidden items
      # @return [Array] an array of IDs for records that both users have hidden
      # @private
      def hidden_ids_in_common_with(klass, user_id)
        user_id = user_id.id if user_id.is_a?(Recommendable.config.user_class)
        Recommendable.redis.sinter(Recommendable::Helpers::RedisKeyMapper.hidden_set_for(klass, id), Recommendable::Helpers::RedisKeyMapper.hidden_set_for(klass, user_id))
      end
    end
  end
end
