module Recommendable
  module Ratable
    module Bookmarkable
      # Fetch a list of users that have liked this item.
      #
      # @return [Array] a list of users that have liked this item
      def bookmarked_by
        Recommendable.query(Recommendable.config.user_class, bookmarked_by_ids)
      end

      # Get the number of users that have liked this item
      #
      # @return [Fixnum] the number of users that have liked this item
      def bookmarked_by_count
        Recommendable.redis.scard(Recommendable::Helpers::RedisKeyMapper.bookmarked_by_set_for(self.class, id))
      end

      # Get the IDs of users that have liked this item.
      #
      # @return [Array] the IDs of users that have liked this item
      def bookmarked_by_ids
        Recommendable.redis.smembers(Recommendable::Helpers::RedisKeyMapper.bookmarked_by_set_for(self.class, id))
      end
    end
  end
end
