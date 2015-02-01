module Recommendable
  module Helpers
    module Calculations
      class Similarity
        attr_reader :user_id, :other_user_id

        def initialize(user_id, other_user_id)
          @user_id = user_id.to_s
          @other_user_id = other_user_id.to_s
          @similarity = 0
          @liked_count = 0
          @disliked_count = 0
        end

        def calculate
          Recommendable.config.ratable_classes.each do |klass|
            sets = liked_and_disliked_sets(klass)
            results = agreements_and_disagreements(*sets)
            count_agreements_and_disagreements(results)
            count_liked_and_disliked(results)
          end

          @similarity /= (@liked_count + @disliked_count).to_f
        end

        private

        def agreements_and_disagreements(liked_set, other_liked_set, disliked_set, other_disliked_set)
          Recommendable.redis.pipelined do
            # Agreements
            Recommendable.redis.sinter(liked_set, other_liked_set)
            Recommendable.redis.sinter(disliked_set, other_disliked_set)

            # Disagreements
            Recommendable.redis.sinter(liked_set, other_disliked_set)
            Recommendable.redis.sinter(disliked_set, other_liked_set)

            Recommendable.redis.scard(liked_set)
            Recommendable.redis.scard(disliked_set)
          end
        end

        def count_agreements_and_disagreements(results)
          add_agreements(results)
          subtract_disagreements(results)
        end

        def add_agreements(results)
          @similarity += results[0].size + results[1].size
        end

        def subtract_disagreements(results)
          @similarity -= results[2].size + results[3].size
        end

        def count_liked_and_disliked(results)
          @liked_count += results[4]
          @disliked_count += results[5]
        end

        def liked_and_disliked_sets(klass)
          liked_set = Recommendable::Helpers::RedisKeyMapper.liked_set_for(klass, user_id)
          other_liked_set = Recommendable::Helpers::RedisKeyMapper.liked_set_for(klass, other_user_id)
          disliked_set = Recommendable::Helpers::RedisKeyMapper.disliked_set_for(klass, user_id)
          other_disliked_set = Recommendable::Helpers::RedisKeyMapper.disliked_set_for(klass, other_user_id)

          return [liked_set, other_liked_set, disliked_set, other_disliked_set]
        end
      end
    end
  end
end
