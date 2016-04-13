require 'gsl'

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
          user_id = user_id.to_s
          other_user_id = other_user_id.to_s
          scored_array = []
          other_scored_array = []
          Recommendable.config.ratable_classes.each do |klass|
            scored_set = scored_set_with_score(klass, user_id)
            other_scored_set = scored_set_with_score(klass, other_user_id)
            next if scored_set.empty? and other_scored_set.empty?

            # create 0 filled array first
            count = Recommendable.config.ratable_class_count[klass.name.to_sym] ||= klass.all.count
            scored_array += Array.new(count, 0)
            other_scored_array += Array.new(count, 0)

            (scored_set.keys + other_scored_set.keys).uniq.each do |ratable_id|
              scored_array.shift
              other_scored_array.shift
              scored_array << (scored_set[ratable_id] || 0)
              other_scored_array << (other_scored_set[ratable_id] || 0)
            end
          end
          #when standard deviation of an array is 0 gsl_pearson returns nan.
          #in case of that, set correlation as 0
          similarity = gsl_pearson(scored_array, other_scored_array) rescue Float::NAN
          similarity.nan? ? 0 : similarity.round(5)
        end

        def scored_set_with_score(klass, user_id)
          scored_set = Recommendable::Helpers::RedisKeyMapper.scored_set_for(klass, user_id)
          Hash[Recommendable.redis.zrange(scored_set, 0, -1, with_scores: true)]
        end

        # Used internally to update the similarity values between this user and all
        # other users. This is called by the background worker.
        def update_similarities_for(user_id)
          user_id = user_id.to_s # For comparison. Redis returns all set members as strings.
          similarity_set = Recommendable::Helpers::RedisKeyMapper.similarity_set_for(user_id)

          # Only calculate similarities for users who have rated the items that
          # this user has rated
          relevant_user_ids = Recommendable.config.ratable_classes.inject([]) do |memo, klass|
            scored_set = Recommendable::Helpers::RedisKeyMapper.scored_set_for(klass, user_id)
            item_ids = Recommendable.redis.zrange(scored_set, 0, -1)

            unless item_ids.empty?
              sets = item_ids.map do |id|
                Recommendable::Helpers::RedisKeyMapper.scored_by_set_for(klass, id)
              end
              memo | Recommendable.redis.sunion(*sets)
            else
              memo
            end
          end

          similarity_values = relevant_user_ids.map { |id| similarity_between(user_id, id) }
          Recommendable.redis.pipelined do
            relevant_user_ids.zip(similarity_values).each do |id, similarity_value|
              next if id == user_id # Skip comparing with self.
              Recommendable.redis.zadd(similarity_set, similarity_value, id)
            end
          end

          if knn = Recommendable.config.nearest_neighbors
            length = Recommendable.redis.zcard(similarity_set)
            kfn = Recommendable.config.furthest_neighbors || 0

            Recommendable.redis.zremrangebyrank(similarity_set, kfn, length - knn - 1)
          end

          true
        end

        # Used internally to update this user's prediction values across all
        # recommendable types. This is called by the background worker.
        #
        # @private
        def update_recommendations_for(user_id)
          user_id = user_id.to_s

          nearest_neighbors = Recommendable.config.nearest_neighbors || Recommendable.config.user_class.count
          Recommendable.config.ratable_classes.each do |klass|
            bookmarked_set = Recommendable::Helpers::RedisKeyMapper.bookmarked_set_for(klass, user_id)
            temp_set = Recommendable::Helpers::RedisKeyMapper.temp_set_for(Recommendable.config.user_class, user_id)
            similarity_set  = Recommendable::Helpers::RedisKeyMapper.similarity_set_for(user_id)
            recommended_set = Recommendable::Helpers::RedisKeyMapper.recommended_set_for(klass, user_id)

            most_similar_user_ids = Recommendable.redis.zrevrange(similarity_set, 0, nearest_neighbors - 1)

            # Get likes from the most similar users
            most_similar_user_set = most_similar_user_ids.inject([]) do |sets, id|
              sets + Recommendable.redis.zrange(
                Recommendable::Helpers::RedisKeyMapper.scored_set_for(klass, id),
                0,
                -1
              )
            end
            return if most_similar_user_set.empty?
            # SDIFF rated items so they aren't recommended
            Recommendable.redis.sadd(temp_set, most_similar_user_set)
            item_ids = Recommendable.redis.sdiff([temp_set, bookmarked_set])
            scores = item_ids.map { |id| [predict_for(user_id, klass, id), id] }
            Recommendable.redis.pipelined do
              scores.each do |s|
                Recommendable.redis.zadd(recommended_set, s[0], s[1])
              end
            end

            Recommendable.redis.del(temp_set)

            if number_recommendations = Recommendable.config.recommendations_to_store
              length = Recommendable.redis.zcard(recommended_set)
              Recommendable.redis.zremrangebyrank(recommended_set, 0, length - number_recommendations - 1)
            end
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
          user_id = user_id.to_s
          item_id = item_id.to_s

          scored_by_set = Recommendable::Helpers::RedisKeyMapper.scored_by_set_for(klass, item_id)
          prediction = similarity_total_for(user_id, scored_by_set, klass, item_id) / Recommendable.redis.scard(scored_by_set).to_f
          prediction.finite? ? prediction.round(5) : 0.0
        end

        def similarity_total_for(user_id, set, klass, item_id)
          similarity_set = Recommendable::Helpers::RedisKeyMapper.similarity_set_for(user_id)
          ids = Recommendable.redis.smembers(set)
          similarity_values = Recommendable.redis.pipelined do
            ids.each do |id|
              Recommendable.redis.zscore(similarity_set, id)
              Recommendable.redis.zscore(Recommendable::Helpers::RedisKeyMapper.scored_set_for(klass, id), item_id)
            end
          end
          similarity_total = similarity_values.in_groups_of(2).inject(0.0) do |sum, value|
            sum + (value[0] * value[1]) rescue sum
          end
          similarity_total
        end

        def update_score_for(klass, id)
          score_set = Recommendable::Helpers::RedisKeyMapper.score_set_for(klass)
          scored_by_set = Recommendable.redis.smembers(Recommendable::Helpers::RedisKeyMapper.scored_by_set_for(klass, id))
          #using sum of score
          score = scored_by_set.inject(0) do |sum, user_id|
            sum + Recommendable.redis.zscore(
              Recommendable::Helpers::RedisKeyMapper.scored_set_for(klass, user_id),
              id
            )
          end
          Recommendable.redis.zadd(score_set, score, id)
          true
        end

        def gsl_pearson(x,y)
          GSL::Stats::correlation(
            GSL::Vector.alloc(x),GSL::Vector.alloc(y)
          )
        end
      end
    end
  end
end
