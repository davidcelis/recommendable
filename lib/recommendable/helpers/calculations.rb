module Recommendable
  module Helpers
    module Calculations
      class << self
        # Calculate a numeric similarity value that can fall between -1.0 and 1.0.
        # A value of 1.0 indicates that both users have rated the same items in
        # the same ways. A value of -1.0 indicates that both users have rated the
        # same items in opposite ways.
        #
        # @param [Fixnum, String] user_id the ID of the first user
        # @param [Fixnum, String] other_user_id the ID of another user
        # @return [Float] the numeric similarity between this user and the passed user
        # @note Similarity values are asymmetrical. `Calculations.similarity_between(user_id, other_user_id)` will not necessarily equal `Calculations.similarity_between(other_user_id, user_id)`
        def similarity_between(user_id, other_user_id)
          similarity = liked_count = disliked_count = 0
          in_common = Recommendable.config.ratable_classes.each do |klass|
            liked_set = Recommendable::Helpers::RedisKeyMapper.liked_set_for(klass, user_id)
            other_liked_set = Recommendable::Helpers::RedisKeyMapper.liked_set_for(klass, other_user_id)
            disliked_set = Recommendable::Helpers::RedisKeyMapper.disliked_set_for(klass, user_id)
            other_disliked_set = Recommendable::Helpers::RedisKeyMapper.disliked_set_for(klass, other_user_id)

            # Agreements
            similarity += Recommendable.redis.sinter(liked_set, other_liked_set).size
            similarity += Recommendable.redis.sinter(disliked_set, other_disliked_set).size

            # Disagreements
            similarity -= Recommendable.redis.sinter(liked_set, other_disliked_set).size
            similarity -= Recommendable.redis.sinter(disliked_set, other_liked_set).size

            liked_count += Recommendable.redis.scard(liked_set)
            disliked_count += Recommendable.redis.scard(disliked_set)
          end

          similarity / (liked_count + disliked_count).to_f
        end

        # Used internally to update the similarity values between this user and all
        # other users. This is called by the background worker.
        def update_similarities_for(user_id)
          user_id = user_id.to_s # For comparison. Redis returns all set members as strings.
          similarity_set = Recommendable::Helpers::RedisKeyMapper.similarity_set_for(user_id)

          # Only calculate similarities for users who have rated the items that
          # this user has rated
          relevant_user_ids = Recommendable.config.ratable_classes.inject([]) do |memo, klass|
            liked_set = Recommendable::Helpers::RedisKeyMapper.liked_set_for(klass, user_id)
            disliked_set = Recommendable::Helpers::RedisKeyMapper.disliked_set_for(klass, user_id)
            item_ids = Recommendable.redis.sunion(liked_set, disliked_set)

            unless item_ids.empty?
              sets = item_ids.map do |id|
                liked_by_set = Recommendable::Helpers::RedisKeyMapper.liked_by_set_for(klass, id)
                disliked_by_set = Recommendable::Helpers::RedisKeyMapper.disliked_by_set_for(klass, id)

                [liked_by_set, disliked_by_set]
              end

              memo | Recommendable.redis.sunion(sets.flatten)
            else
              memo
            end
          end

          relevant_user_ids.each do |id|
            next if id == user_id # Skip comparing with self.
            Recommendable.redis.zadd(similarity_set, similarity_between(user_id, id), id)
          end

          true
        end

        # Used internally to update this user's prediction values across all
        # recommendable types. This is called by the background worker.
        #
        # @private
        def update_recommendations_for(user_id)
          nearest_neighbors = Recommendable.config.nearest_neighbors || Recommendable.config.user_class.count
          Recommendable.config.ratable_classes.each do |klass|
            similarity_set = Recommendable::Helpers::RedisKeyMapper.similarity_set_for(user_id)
            recommended_set = Recommendable::Helpers::RedisKeyMapper.recommended_set_for(klass, user_id)
            similar_user_ids = Recommendable.redis.zrevrange(similarity_set, 0, nearest_neighbors - 1)

            sets_to_union = similar_user_ids.inject([]) do |sets, id|
              sets << Recommendable::Helpers::RedisKeyMapper.liked_set_for(klass, id)
            end

            next if sets_to_union.empty?
            scores = Recommendable.redis.sunion(sets_to_union).map { |id| [predict_for(user_id, klass, id), id] }
            next if scores.empty?
            Recommendable.redis.zadd(recommended_set, scores)
          end

          true
        end

        # Predict how likely it is that a user will like an item. This probability
        # is not based on percentage. 0.0 indicates that the user will neither like
        # nor dislike the item. Values that approach Infinity indicate a rising
        # likelihood of liking the item while values approaching -Infinity
        # indicate a rising probability of disliking the item.
        #
        # @param [Fixnum, String] user_id the user's ID
        # @param [Class] klass the item's class
        # @param [Fixnum, String] item_id the item's ID
        # @return [Float] the probability that the user will like the item
        def predict_for(user_id, klass, item_id)
          similarity_set = Recommendable::Helpers::RedisKeyMapper.similarity_set_for(user_id)
          liked_by_set = Recommendable::Helpers::RedisKeyMapper.liked_by_set_for(klass, item_id)
          disliked_by_set = Recommendable::Helpers::RedisKeyMapper.disliked_by_set_for(klass, item_id)
          similarity_sum = 0.0

          Recommendable.redis.smembers(liked_by_set).inject(similarity_sum) do |sum, id|
            sum += Recommendable.redis.zscore(similarity_set, id).to_f
          end
          Recommendable.redis.smembers(disliked_by_set).inject(similarity_sum) do |sum, id|
            sum -= Recommendable.redis.zscore(similarity_set, id).to_f
          end

          liked_by_count = Recommendable.redis.scard(liked_by_set)
          disliked_by_count = Recommendable.redis.scard(disliked_by_set)
          prediction = similarity_sum / (liked_by_count + disliked_by_count).to_f
          prediction.finite? ? prediction : 0.0
        end

        def update_score_for(klass, id)
          score_set = Recommendable::Helpers::RedisKeyMapper.score_set_for(klass)
          liked_by_set = Recommendable::Helpers::RedisKeyMapper.liked_by_set_for(klass, id)
          disliked_by_set = Recommendable::Helpers::RedisKeyMapper.disliked_by_set_for(klass, id)
          liked_by_count = Recommendable.redis.scard(liked_by_set)
          disliked_by_count = Recommendable.redis.scard(disliked_by_set)

          return 0.0 unless liked_by_count + disliked_by_count > 0

          z = 1.96
          n = liked_by_count + disliked_by_count
          phat = liked_by_count / n.to_f

          begin
            score = (phat + z*z/(2*n) - z * Math.sqrt((phat*(1-phat)+z*z/(4*n))/n))/(1+z*z/n)
          rescue Math::DomainError
            score = 0
          end

          Recommendable.redis.zadd(score_set, score, id)
          true
        end
      end
    end
  end
end
