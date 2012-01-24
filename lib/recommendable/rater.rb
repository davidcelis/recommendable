module Recommendable
  module Rater
    def included(base)
      base.extend ClassMethods
    end
    
    module ClassMethods
      def acts_as_liker
        class_eval do
          send :has_many, :likes, :as => :likeable
          send :include, LikeMethods
          send :include, RecommendationMethods
        end
      end
      
      def acts_as_disliker
        class_eval do
          send :has_many, :dislikes, :as => :dislikeable
          send :include, DislikeMethods
          send :include, RecommendationMethods
        end
      end
    end
    
    module LikeMethods
      def like(item)
        self.create_like(item)
      end
      
      def likes?(item)
        self.likes.where(:likeable_id => item.id, :likeable_type => item.class.to_s).first
      end
      
      def unlike(item)
        return unless like = self.likes?(item)
        like.destroy
      end
      
      def likes_for(klass)
        self.likes.where(:likeable_type => klass.to_s)
      end
    end
    
    module DislikeMethods
      def dislike(item)
        self.create_dislike(item)
      end
      
      def dislikes?(item)
        self.dislikes.where(:dislikeable_id => item.id, :dislikeable_type => item.class.to_s).first
      end
      
      def undislike(item)
        return unless dislike = self.dislikes?(item)
        dislike.destroy
      end
      
      def dislikes_for(klass)
        self.dislikes.where(:dislikeable_type => klass.to_s)
      end
    end
    
    module RecommendationMethods
      def similarity_with(rater)
        similarity = 0.0

        return similarity if like_count + dislike_count == 0

        agreements = common_likes_with(rater).size + common_dislikes(rater).size
        disagreements = disagreements_with(rater).size
        similarity = (agreements - disagreements).to_f / (like_count + dislike_count)

        return similarity
      end
      
      def common_likes_with(rater)
        Recommendable.redis.sinter "rater:#{id}:likes", "rater:#{rater.id}:likes"
      end
      
      def common_dislikes_with(rater)
        Recommendable.redis.sinter "rater:#{id}:dislikes", "rater:#{rater.id}:dislikes"
      end
      
      def disagreements_with(rater)
        Recommendable.redis.sinter("rater:#{id}:likes", "rater:#{rater.id}:dislikes") +
        Recommendable.redis.sinter("rater:#{id}:dislikes", "rater:#{rater.id}:likes")
      end
      
      def similar_raters(options)
        defaults = { :count => 10 }
        options.merge! defaults
        
        ids = Recommendable.redis.zrevrange "user_#{id}:similarities", 0, options[:count] - 1
        class.find ids, order: "field(id, #{ids.join(',')})"
      end
      
      
      def update_similarities
        self.class.find_each do |rater|
          next if self == rater
          
          similarity = similarity_with(rater)
          Recommendable.redis.zadd "rater:#{id}:similarities", similarity, rater.id
          Recommendable.redis.zadd "rater:#{rater.id}:similarities", similarity, id
        end
      end
      
      def update_predictions_for(klass)
        klass.find_each do |item|
          unless has_liked?(item) || has_disliked?(item)
            prediction = predict(item)
            Recommendable.redis.zadd "rater:#{id}:predictions", prediction, item.id if prediction
          end
        end
      end
      
      def recommend_for(klass)
        predictions = []
        return predictions if like_count + dislike_count == 0
        return predictions if Recommendable.redis.zcard("rater:#{id}:predictions") == 0
        i = options[:offset]

        until predictions.size == count
          item = klass.find Recommendable.redis.zrevrange("rater:#{id}:predictions", i, i).first
          predictions << item unless has_rated?(item) || has_hidden?(beer)
          i += 1
        end

        return predictions
      end
      
      def predict(item)
        sum = 0.0
        prediction = 0.0

        Recommendable.redis.smembers("rateable:#{item.id}:liked_by").inject(sum) {|r, sum| sum += Recommendable.redis.zscore("rater:#{id}:similarities", r)}
        Recommendable.redis.smembers("rateable:#{item.id}:disliked_by").inject(sum) {|r, sum| sum -= Recommendable.redis.zscore("rater:#{id}:similarities", r)}

        rated_by = Recommendable.redis.scard("rateable:#{item.id}:liked_by") + Recommendable.redis.scard("rateable:#{item.id}:disliked_by")
        prediction = similarity_sum / rated_by.to_f unless rated_by == 0
      end
      
      def probability_of_liking(item)
        Recommendable.redis.zscore "rater:#{id}:predictions", item.id
      end
      
      def probability_of_disliking(item)
        -probability_of_liking(item)
      end
    end
  end
end