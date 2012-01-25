module Recommendable
  module ActsAsRateable
    def self.included(base)
      base.extend ClassMethods
    end
    
    module ClassMethods
      def acts_as_rateable
        class_eval do
          has_many :likes, :as => :likeable, :dependent => :destroy, :class_name => "Recommendable::Like"
          has_many :dislikes, :as => :dislikeable, :dependent => :destroy, :class_name => "Recommendable::Dislike"
          has_many :liked_by, :through => :likes, :source => :user
          has_many :disliked_by, :through => :dislikes, :source => :user
          
          include LikeableMethods
          include DislikeableMethods
        end
      end
    end
    
    module LikeableMethods
      def build_liked_by_set
        set = "#{likeable_type}:#{id}:liked_by"
        liked_by.each {|rater| Recommendable.redis.sadd set, rater.id}
        return set
      end
    end
    
    module DislikeableMethods
      def build_disliked_by_set
        set = "#{dislikeable_type}:#{id}:disliked_by"
        disliked_by.each {|rater| Recommendable.redis.sadd set, rater.id}
        return set
      end
    end
  end
end