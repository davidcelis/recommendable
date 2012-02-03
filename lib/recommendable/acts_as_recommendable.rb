module Recommendable
  module ActsAsRecommendable
    extend ActiveSupport::Concern

    module ClassMethods
      def acts_as_recommendable
        class_eval do
          Recommendable.recommendable_classes << self
          
          has_many :likes, :as => :likeable, :dependent => :destroy, :class_name => "Recommendable::Like"
          has_many :dislikes, :as => :dislikeable, :dependent => :destroy, :class_name => "Recommendable::Dislike"
          has_many :liked_by, :through => :likes, :source => :user
          has_many :disliked_by, :through => :dislikes, :source => :user
          has_many :ignores, :as => :ignoreable, :dependent => :destroy, :class_name => "Recommendable::Ignore"
          has_many :stashes, :as => :stashable, :dependent => :destroy, :class_name => "Recommendable::StashedItem"
          
          include LikeableMethods
          include DislikeableMethods
          
          def self.acts_as_recommendable? ; true ; end

          def has_been_rated?
            likes.count + dislikes.count > 0
          end
          
          # Used for setup purposes. Calls convenience methods to create sets
          # in redis of users that both like and dislike this object.
          # @return [Array] an array containing the liked_by set and the disliked_by set
          # @protected
          def create_recommendable_sets
            [create_liked_by_set, create_disliked_by_set]
          end
          
          # Used for teardown purposes. Destroys the sets in redis created by
          # {#create_recommendable_sets}
          # @protected
          def destroy_recommendable_sets
            Recommendable.redis.del "#{self.class}:#{id}:liked_by"
            Recommendable.redis.del "#{self.class}:#{id}:disliked_by"
          end

          protected :create_recommendable_sets, :destroy_recommendable_sets
          private :likes, :dislikes, :ignores, :stashes
        end
      end

      def acts_as_recommendable? ; false ; end
    end

    # Instance methods.
    def recommendable? ; self.class.acts_as_recommendable? ; end

    def redis_key ; "#{self.class}:#{id}" ; end

    protected :redis_key
    
    module LikeableMethods
      # Used for setup purposes. Creates a set in redis containing users that
      # have liked this object.
      # @private
      # @return [String] the key in Redis pointing to the set
      def create_liked_by_set
        set = "#{self.class}:#{id}:liked_by"
        liked_by.each {|rater| Recommendable.redis.sadd set, rater.id}
        return set
      end

      private :create_liked_by_set
    end
    
    module DislikeableMethods
      # Used for setup purposes. Creates a set in redis containing users that
      # have disliked this object.
      # @private
      # @return [String] the key in Redis pointing to the set
      def create_disliked_by_set
        set = "#{self.class}:#{id}:disliked_by"
        disliked_by.each {|rater| Recommendable.redis.sadd set, rater.id}
        return set
      end

      private :create_disliked_by_set
    end
  end
end
