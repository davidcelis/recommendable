module Recommendable
  module ActsAsRecommendable
    extend ActiveSupport::Concern

    module ClassMethods
      def acts_as_recommendable
        class_eval do
          Recommendable.recommendable_classes << self
          
          has_many :recommendable_likes, :as => :likeable, :dependent => :destroy,
                                         :class_name => "Recommendable::Like"
          has_many :recommendable_dislikes, :as => :dislikeable, :dependent => :destroy,
                                            :class_name => "Recommendable::Dislike"
          has_many :recommendable_ignores, :as => :ignorable, :dependent => :destroy,
                                           :class_name => "Recommendable::Ignore"
          has_many :recommendable_stashes, :as => :stashable, :dependent => :destroy,
                                           :class_name => "Recommendable::Stash"

          has_many :liked_by, :through => :recommendable_likes, :source => :user,
                              :foreign_key => :user_id, :class_name => Recommendable.user_class.to_s
          has_many :disliked_by, :through => :recommendable_dislikes, :source => :user,
                                 :foreign_key => :user_id, :class_name => Recommendable.user_class.to_s
          
          include LikeableMethods
          include DislikeableMethods

          before_destroy :remove_from_scores, :remove_from_recommendations
          
          def self.acts_as_recommendable?() true end

          def been_rated?
            recommendable_likes.count + recommendable_dislikes.count > 0
          end

          # Returns an array of users that have liked or disliked this item.
          # @return [Array] an array of users
          def rated_by
            liked_by + disliked_by
          end

          def self.top count = 1
            ids = Recommendable.redis.zrevrange(self.score_set, 0, count - 1).map(&:to_i)

            items = self.find ids
            return items.first if count == 1

            return items.sort_by { |item| ids.index(item.id) }
          end

          private

          def update_score
            return 0 unless been_rated?

            z = 1.96
            n = recommendable_likes.count + recommendable_dislikes.count

            phat = recommendable_likes.count / n.to_f
            score = (phat + z*z/(2*n) - z * Math.sqrt((phat*(1-phat)+z*z/(4*n))/n))/(1+z*z/n)

            Recommendable.redis.zadd self.class.score_set, score, self.id
            true
          end

          def remove_from_scores
            Recommendable.redis.zrem self.class.score_set, self.id
            true
          end

          def remove_from_recommendations
            Recommendable.user_class.find_each do |user|
              user.send :completely_unrecommend, self
            end
          end
          
          # Used for setup purposes. Calls convenience methods to create sets
          # in redis of users that both like and dislike this object.
          # @return [Array] an array containing the liked_by set and the disliked_by set
          # @private
          def create_recommendable_sets
            [create_liked_by_set, create_disliked_by_set]
          end
          
          # Used for teardown purposes. Destroys the sets in redis created by
          # {#create_recommendable_sets}
          # @private
          def destroy_recommendable_sets
            Recommendable.redis.del "#{self.class.base_class}:#{id}:liked_by"
            Recommendable.redis.del "#{self.class.base_class}:#{id}:disliked_by"
          end

          # Returns an array of IDs of users that have liked or disliked this item.
          # @return [Array] an array of user IDs
          # @private
          def rates_by
            recommendable_likes.map(&:user_id) + recommendable_dislikes.map(&:user_id)
          end

          def self.score_set
            "#{self}:sorted"
          end

          private :recommendable_likes, :recommendable_dislikes,
                  :recommendable_ignores, :recommendable_stashes
        end
      end

      def acts_as_recommendable?() false end

      def sti?
        self.base_class != self && self.base_class.table_name == self.table_name
      end

      private
    end

    # Instance methods.
    def recommendable?() self.class.acts_as_recommendable? end

    def redis_key() "#{self.class.base_class}:#{id}" end

    protected :redis_key
    
    module LikeableMethods
      # Retrieve the number of likes this object has received. Cached in Redis.
      # @return [Fixnum] the number of times this object has been liked
      def like_count
        Recommendable.redis.get("#{redis_key}:like_count").to_i
      end

      private

      # Updates the cache for how many times this object has been liked.
      # @private
      def update_like_count
        Recommendable.redis.set "#{redis_key}:like_count", liked_by.count
      end

      # Used for setup purposes. Creates a set in redis containing users that
      # have liked this object.
      # @private
      # @return [String] the key in Redis pointing to the set
      def create_liked_by_set
        set = "#{redis_key}:liked_by"
        liked_by.each { |rater| Recommendable.redis.sadd set, rater.id }
        return set
      end
    end
    
    module DislikeableMethods
      # Retrieve the number of dislikes this object has received. Cached in Redis.
      # @return [Fixnum] the number of times this object has been disliked
      def dislike_count
        Recommendable.redis.get("#{redis_key}:dislike_count").to_i
      end

      private

      # Updates the cache for how many times this object has been disliked.
      # @private
      def update_dislike_count
        Recommendable.redis.set "#{redis_key}:dislike_count", disliked_by.count
      end

      # Used for setup purposes. Creates a set in redis containing users that
      # have disliked this object.
      # @private
      # @return [String] the key in Redis pointing to the set
      def create_disliked_by_set
        set = "#{redis_key}:disliked_by"
        disliked_by.each { |rater| Recommendable.redis.sadd set, rater.id }
        return set
      end
    end
  end
end
