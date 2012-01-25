require 'active_support/concern'

module Recommendable
  module ActsAsRater
    extend ActiveSupport::Concern
    
    def can_things_be_rated_by?(user)
      user.respond_to?(:like) || user.respond_to?(:dislike)
    end
    
    module ClassMethods
      def acts_as_recommendable
        class_eval do
          has_many :likes, :class_name => "Recommendable::Like"
          has_many :dislikes, :class_name => "Recommendable::Dislike"
          
          include LikeMethods
          include DislikeMethods 
          include RecommendationMethods
        end
      end
    end
    
    module LikeMethods
      def like(item)
        likes.create(:likeable_id => item.id, :likeable_type => item.class.to_s)
      end
      
      def likes?(item)
        likes.exists?(:likeable_id => item.id, :likeable_type => item.class.to_s)
      end
      
      def unlike(item)
        return unless likes?(item)
        likes.where(:likeable_id => item.id, :likeable_type => item.class.to_s).first.destroy
      end
      
      def liked_records
        likes.map {|like| like.likeable_type.constantize.find(like.likeable_id)}
      end
      
      def likes_for(klass)
        klass = klass.is_a?(String) ? klass.camelize.constantize : klass
        likes.where(:likeable_type => klass.to_s)
      end
      
      def liked_records_for(klass)
        klass = klass.is_a?(String) ? klass.camelize.constantize : klass
        klass.find likes_for(klass).map(&:dislikeable_id)
      end
    end
    
    module DislikeMethods
      def dislike(item)
        dislikes.create(:dislikeable_id => item.id, :dislikeable_type => item.class.to_s)
      end
      
      def dislikes?(item)
        dislikes.exists?(:dislikeable_id => item.id, :dislikeable_type => item.class.to_s)
      end
      
      def undislike(item)
        return unless dislikes?(item)
        dislikes.where(:dislikeable_id => item.id, :dislikeable_type => item.class.to_s).first.destroy
      end
      
      def disliked_records
        dislikes.map {|dislike| dislike.dislikeable_type.constantize.find(dislike.dislikeable_id)}
      end
      
      def dislikes_for(klass)
        klass = klass.is_a?(String) ? klass.camelize.constantize : klass
        dislikes.where(:dislikeable_type => klass.to_s)
      end
      
      def disliked_records_for(klass)
        klass = klass.is_a?(String) ? klass.camelize.constantize : klass
        klass.find dislikes_for(klass).map(&:dislikeable_id)
      end
    end
    
    module RecommendationMethods
      # def similarity_with(rater)
      #   similarity = 0.0
      # 
      #   return similarity if like_count + dislike_count == 0
      # 
      #   agreements = common_likes_with(rater).size + common_dislikes(rater).size
      #   disagreements = disagreements_with(rater).size
      #   similarity = (agreements - disagreements).to_f / (like_count + dislike_count)
      # 
      #   return similarity
      # end
      # 
      # def common_likes_with(rater)
      #   Recommendable.redis.sinter "rater:#{id}:likes", "rater:#{rater.id}:likes"
      # end
      # 
      # def common_dislikes_with(rater)
      #   Recommendable.redis.sinter "rater:#{id}:dislikes", "rater:#{rater.id}:dislikes"
      # end
      # 
      # def disagreements_with(rater)
      #   Recommendable.redis.sinter("rater:#{id}:likes", "rater:#{rater.id}:dislikes") +
      #   Recommendable.redis.sinter("rater:#{id}:dislikes", "rater:#{rater.id}:likes")
      # end
      # 
      # def similar_raters(options)
      #   defaults = { :count => 10 }
      #   options.merge! defaults
      #   
      #   ids = Recommendable.redis.zrevrange "user_#{id}:similarities", 0, options[:count] - 1
      #   class.find ids, order: "field(id, #{ids.join(',')})"
      # end
      # 
      # 
      # def update_similarities
      #   self.class.find_each do |rater|
      #     next if self == rater
      #     
      #     similarity = similarity_with(rater)
      #     Recommendable.redis.zadd "rater:#{id}:similarities", similarity, rater.id
      #     Recommendable.redis.zadd "rater:#{rater.id}:similarities", similarity, id
      #   end
      # end
      # 
      # def update_predictions_for(klass)
      #   klass.find_each do |item|
      #     unless has_liked?(item) || has_disliked?(item)
      #       prediction = predict(item)
      #       Recommendable.redis.zadd "rater:#{id}:predictions", prediction, item.id if prediction
      #     end
      #   end
      # end
      # 
      # def recommend_for(klass)
      #   predictions = []
      #   return predictions if like_count + dislike_count == 0
      #   return predictions if Recommendable.redis.zcard("rater:#{id}:predictions") == 0
      #   i = options[:offset]
      # 
      #   until predictions.size == count
      #     item = klass.find Recommendable.redis.zrevrange("rater:#{id}:predictions", i, i).first
      #     predictions << item unless has_rated?(item) || has_hidden?(beer)
      #     i += 1
      #   end
      # 
      #   return predictions
      # end
      # 
      # def predict(item)
      #   sum = 0.0
      #   prediction = 0.0
      # 
      #   Recommendable.redis.smembers("rateable:#{item.id}:liked_by").inject(sum) {|r, sum| sum += Recommendable.redis.zscore("rater:#{id}:similarities", r)}
      #   Recommendable.redis.smembers("rateable:#{item.id}:disliked_by").inject(sum) {|r, sum| sum -= Recommendable.redis.zscore("rater:#{id}:similarities", r)}
      # 
      #   rated_by = Recommendable.redis.scard("rateable:#{item.id}:liked_by") + Recommendable.redis.scard("rateable:#{item.id}:disliked_by")
      #   prediction = similarity_sum / rated_by.to_f unless rated_by == 0
      # end
      # 
      # def probability_of_liking(item)
      #   Recommendable.redis.zscore "rater:#{id}:predictions", item.id
      # end
      # 
      # def probability_of_disliking(item)
      #   -probability_of_liking(item)
      # end
    end
  end
end