module Recommendable
  module ActsAsRecommendable
    def self.included(base)
      base.extend ClassMethods
    end
    
    module ClassMethods
      def acts_as_recommendable
        class_eval do
          Recommendable.recommendable_classes << self
          
          has_many :likes, :as => :likeable, :dependent => :destroy, :class_name => "Recommendable::Like"
          has_many :dislikes, :as => :dislikeable, :dependent => :destroy, :class_name => "Recommendable::Dislike"
          has_many :liked_by, :through => :likes, :source => :user
          has_many :disliked_by, :through => :dislikes, :source => :user
          has_many :ignores, :as => :ignoreable, :dependent => :destroy, :class_name => "Recommendable::Ignore"
          
          include LikeableMethods
          include DislikeableMethods
          
          def create_recommendable_sets
            [create_liked_by_set, create_disliked_by_set]
          end
          
          def destroy_recommendable_sets
            Recommendable.redis.del "#{self.class}:#{id}:liked_by"
            Recommendable.redis.del "#{self.class}:#{id}:disliked_by"
          end
        end
      end
    end
    
    module LikeableMethods
      def create_liked_by_set
        set = "#{self.class}:#{id}:liked_by"
        liked_by.each {|rater| Recommendable.redis.sadd set, rater.id}
        return set
      end
    end
    
    module DislikeableMethods
      def create_disliked_by_set
        set = "#{self.class}:#{id}:disliked_by"
        disliked_by.each {|rater| Recommendable.redis.sadd set, rater.id}
        return set
      end
    end
  end
end