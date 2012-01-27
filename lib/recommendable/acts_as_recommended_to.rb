require 'active_support/concern'

module Recommendable
  module ActsAsRecommendedTo
    extend ActiveSupport::Concern
    
    def things_can_be_recommended_to?(user)
      user.respond_to?(:like) || user.respond_to?(:dislike)
    end
    
    module ClassMethods
      def acts_as_recommended_to
        class_eval do
          has_many :likes, :class_name => "Recommendable::Like", :dependent => :destroy
          has_many :dislikes, :class_name => "Recommendable::Dislike", :dependent => :destroy
          has_many :ignores, :class_name => "Recommendable::Ignore", :dependent => :destroy
          
          include LikeMethods
          include DislikeMethods 
          include IgnoreMethods
          include RecommendationMethods
        end
      end
    end
    
    module LikeMethods
      def like(item)
        likes.create!(:likeable_id => item.id, :likeable_type => item.class.to_s)
        Recommendable.redis.zrem "#{self.class}:#{id}:predictions", "#{item.class}:#{item.id}"
      end
      
      def likes?(item)
        likes.exists?(:likeable_id => item.id, :likeable_type => item.class.to_s)
      end
      
      def unlike(item)
        likes.where(:likeable_id => item.id, :likeable_type => item.class.to_s).first.try(:destroy)
      end
      
      def liked_objects
        likes.map {|like| like.likeable}
      end
      
      def likes_for(klass)
        likes.where(:likeable_type => klassify(klass).to_s)
      end
      
      def liked_objects_for(klass)
        klassify(klass).find likes_for(klass).map(&:likeable_id)
      end
    end
    
    module DislikeMethods
      def dislike(item)
        dislikes.create!(:dislikeable_id => item.id, :dislikeable_type => item.class.to_s)
        Recommendable.redis.zrem "#{self.class}:#{id}:predictions", "#{item.class}:#{item.id}"
      end
      
      def dislikes?(item)
        dislikes.exists?(:dislikeable_id => item.id, :dislikeable_type => item.class.to_s)
      end
      
      def undislike(item)
        dislikes.where(:dislikeable_id => item.id, :dislikeable_type => item.class.to_s).first.try(:destroy)
      end
      
      def disliked_objects
        dislikes.map {|dislike| dislike.dislikeable}
      end
      
      def dislikes_for(klass)
        dislikes.where(:dislikeable_type => klassify(klass).to_s)
      end
      
      def disliked_objects_for(klass)
        klassify(klass).find dislikes_for(klass).map(&:dislikeable_id)
      end
    end
    
    module IgnoreMethods
      def ignore(item)
        ignores.create!(:ignoreable_id => item.id, :ignoreable_type => item.class.to_s)
        Recommendable.redis.zrem "#{self.class}:#{id}:predictions", "#{item.class}:#{item.id}"
      end
      
      def has_ignored?(item)
        ignores.exists?(:ignoreable_id => item.id, :ignoreable_type => item.class.to_s)
      end
      
      def unignore(item)
        ignores.where(:ignoreable_id => item.id, :ignoreable_type => item.class.to_s).first.try(:destroy)
      end
      
      def ignored_objects
        ignores.map {|ignore| ignore.ignoreable}
      end
      
      def ignores_for(klass)
        ignores.where(:ignoreable_type => klassify(klass).to_s)
      end
      
      def ignored_objects_for(klass)
        klassify(klass).find ignores_for(klass).map(&:ignoreable_id)
      end
    end
    
    module RecommendationMethods
      def has_rated?(item)
        likes?(item) || dislikes?(item)
      end
      
      def has_rated_anything?
        likes.count > 0 || dislikes.count > 0
      end
      
      def similarity_with(rater)
        rater.create_recommended_to_sets
        agreements = common_likes_with(rater).size + common_dislikes(rater).size
        disagreements = disagreements_with(rater).size
        
        similarity = (agreements - disagreements).to_f / (likes.count + dislikes)
        rater.destroy_recommended_to_sets
        
        return similarity
      end
      
      def common_likes_with(rater, options = {})
        defaults = { :class => nil }
        options = defaults.merge(options)
        
        if options[:class]
          Recommendable.redis.sinter "#{self.class}:#{id}:likes:#{options[:class]}", "#{rater.class}:#{rater.id}:likes:#{options[:class]}"
        else
          Recommendable.recommendable_classes.map do |klass|
            Recommendable.redis.sinter("#{self.class}:#{id}:likes:#{klass}", "#{rater.class}:#{rater.id}:likes:#{klass}").map {|id| "#{klass}:#{id}"}
          end
        end
      end
      
      def common_dislikes_with(rater, options = {})
        defaults = { :class => nil }
        options = defaults.merge(options)
        
        if options[:class]
          Recommendable.redis.sinter "#{self.class}:#{id}:dislikes:#{options[:class]}", "#{rater.class}:#{rater.id}:dislikes:#{options[:class]}"
        else
          Recommendable.recommendable_classes.map do |klass|
            Recommendable.redis.sinter("#{self.class}:#{id}:dislikes:#{klass}", "#{rater.class}:#{rater.id}:dislikes:#{klass}").map {|id| "#{klass}:#{id}"}
          end
        end
      end
      
      def disagreements_with(rater, options = {})
        defaults = { :class => nil }
        options = defaults.merge(options)
        
        if options[:class]
          Recommendable.redis.sinter("#{self.class}:#{id}:likes:#{options[:class]}", "#{rater.class}:#{rater.id}:dislikes").size +
          Recommendable.redis.sinter("#{self.class}:#{id}:dislikes:#{options[:class]}", "#{rater.class}:#{rater.id}:likes").size
        else
          Recommendable.recommendable_classes.inject(0) do |sum, klass|
            sum += Recommendable.redis.sinter("#{self.class}:#{id}:likes:#{klass}", "#{rater.class}:#{rater.id}:dislikes").size
            sum += Recommendable.redis.sinter("#{self.class}:#{id}:dislikes:#{klass}", "#{rater.class}:#{rater.id}:likes").size
          end
        end
      end
      
      def similar_raters(options)
        defaults = { :count => 10 }
        options = defaults.merge(options)
        
        rater_ids = Recommendable.redis.zrevrange "#{self.class}:#{id}:similarities", 0, options[:count] - 1
        Recommendable.user_class.find rater_ids, order: "field(id, #{ids.join(',')})"
      end
      
      def update_similarities
        return unless has_rated_anything?
        self.create_recommended_to_sets
        
        Recommendable.user_class.find_each do |rater|
          next unless things_can_be_recommended_to?(rater) && self != rater
          
          similarity = similarity_with(rater)
          Recommendable.redis.zadd "#{self.class}:#{id}:similarities", similarity, "#{rater.id}"
          Recommendable.redis.zadd "#{rater.class}:#{rater.id}:similarities", similarity, "#{id}"
        end
        
        self.destroy_recommended_to_sets
      end
      
      def update_recommendations
        Recommendable.recommendable_classes.each do |klass|
          update_predictions_for(klass)
        end
      end
      
      def update_recommendations_for(klass)
        klass.find_each do |item|
          unless has_rated?(item)
            prediction = predict(item)
            Recommendable.redis.zadd "#{self.class}:#{id}:predictions:#{item.class}", prediction, "#{item.class}:#{item.id}" if prediction
          end
        end
      end
      
      def recommendations(options = {})
        defaults = { :count => 10 }
        options = defaults.merge options

        unioned_predictions = "#{self.class}:#{id}:predictions"
        Recommendable.redis.zunionstore unioned_predictions, Recommendable.recommendable_classes.map {|klass| "#{self.class}:#{id}:predictions:#{klass}"}
        return [] if likes.count + dislikes.count == 0 || Recommendable.redis.zcard(unioned_predictions) == 0
        
        recommendations = Recommendable.redis.zrevrange(unioned_predictions, 0, options[:count]).map do |item|
          item.klass.find(item.likeable_id)
        end
        
        Recommendable.redis.del unioned_predictions
        recommendations
      end
      
      def recommendations_for(klass, options = {})
        defaults = { :count => 10 }
        options = defaults.merge options
        
        recommendations = []
        return recommendations if likes_for(klass).count + dislikes_for(klass).count == 0 || Recommendable.redis.zcard("#{self.class}:#{id}:predictions:#{klass}") == 0
      
        until predictions.size == options[:count]
          i += 1
          item = klass.find(Recommendable.redis.zrevrange("#{self.class}:#{id}:predictions:#{klass}", i, i).first.split(":")[1])
          recommendations << item unless has_ignored?(item)
        end
      
        return recommendations
      end
      
      def predict(item)
        liked_by, disliked_by = item.create_recommendable_sets
        rated_by = Recommendable.redis.scard(liked_by) + Recommendable.redis.scard(disliked_by)
        sum = 0.0
        prediction = 0.0
      
        Recommendable.redis.smembers(liked_by).inject(sum) {|r, sum| sum += Recommendable.redis.zscore("#{self.class}:#{id}:similarities", r) }
        Recommendable.redis.smembers(disliked_by).inject(sum) {|r, sum| sum -= Recommendable.redis.zscore("#{self.class}:#{id}:similarities", r) }
      
        prediction = similarity_sum / rated_by.to_f
        
        item.destroy_recommendable_sets
        
        return prediction
      end
      
      def probability_of_liking(item)
        Recommendable.redis.zscore "#{self.class}:#{id}:predictions:#{item.class}", "#{item.class}:#{item.id}"
      end
      
      def probability_of_disliking(item)
        -probability_of_liking(item)
      end
      
      private
      
      def create_recommended_to_sets
        Recommendable.recommendable_class.each do |klass|
          likes_for(klass).each {|like| Recommendable.redis.sadd "#{self.class}:#{id}:likes:#{klass}", like.likeable_id }
          dislikes_for(klass).each {|dislike| Recommendable.redis.sadd "#{self.class}:#{id}:dislikes:#{klass}", dislike.dislikeable_id }
        end
      end
      
      def destroy_recommended_to_sets
        Recommendable.recommendable_classes.each do |klass|
          Recommendable.redis.del "#{self.class}:#{id}:likes:#{klass}"
          Recommendable.redis.del "#{self.class}:#{id}:dislikes:#{klass}"
        end
      end
    end
    
    private
    
    def klassify(klass)
      (klass.is_a?(String) || klass.is_a?(Symbol)) ? klass.to_s.camelize.constantize : klass
    end
  end
end