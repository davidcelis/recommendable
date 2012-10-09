module Recommendable
  module Ratable
    module Dislikable
      # Fetch a list of users that have disliked this item.
      #
      # @return [Array] a list of users that have disliked this item
      def disliked_by
        Recommendable.query(Recommendable.config.user_class, disliked_by_ids)
      end

      # Get the number of users that have disliked this item
      #
      # @return [Fixnum] the number of users that have disliked this item
      def disliked_by_count
        Recommendable.redis.scard(Recommendable::Helpers::RedisKeyMapper.disliked_by_set_for(self.class, id))
      end

      # Get the IDs of users that have disliked this item.
      #
      # @return [Array] the IDs of users that have disliked this item
      def disliked_by_ids
        Recommendable.redis.smembers(Recommendable::Helpers::RedisKeyMapper.disliked_by_set_for(self.class, id))
      end
    end
  end
end
