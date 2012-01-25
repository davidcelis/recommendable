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
          include LikeableMethods
          include DislikeableMethods
        end
      end
    end
    
    module LikeableMethods
      
    end
    
    module DislikeableMethods
      
    end
  end
end