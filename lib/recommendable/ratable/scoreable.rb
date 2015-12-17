module Recommendable
  module Ratable
    module Scoreable
      # Fetch a list of users that have scored this item.
      #
      # @return [Array] a list of users that have scored this item
      def scored_by
        Recommendable.query(Recommendable.config.user_class, scored_by_ids)
      end

      # Get the number of users that have scored this item
      #
      # @return [Fixnum] the number of users that have scored this item
      def scored_by_count
        Recommendable.redis.scard(Recommendable::Helpers::RedisKeyMapper.scored_by_set_for(self.class, id))
      end

      # Get the IDs of users that have scored this item.
      #
      # @return [Array] the IDs of users that have scored this item
      def scored_by_ids
        Recommendable.redis.smembers(Recommendable::Helpers::RedisKeyMapper.scored_by_set_for(self.class, id))
      end
    end
  end
end
