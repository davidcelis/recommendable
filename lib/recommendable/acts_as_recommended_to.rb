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
      # Creates a Recommendable::Like to associate self to a passed object. If
      # `self` is currently found to have disliked `object`, the corresponding
      # Recommendable::Dislike will be destroyed.
      #
      # @param [Object] object the object you want `self` to like.
      # @return true if `object` has been liked
      # @raise [RecordNotRecommendableError] if you have not declared the passed
      # object's model to `act_as_recommendable`
      def like(object)
        raise RecordNotRecommendableError unless Recommendable.recommendable_classes.include?(object.class)
        undislike(object) if dislikes?(object)
        Recommendable.redis.zrem "#{self.class}:#{id}:predictions", "#{object.class}:#{object.id}"
        likes.create!(:likeable_id => object.id, :likeable_type => object.class.to_s)
        Resque.enqueue RecommendationRefresher, self.id
        true
      end
      
      # Checks to see if `self` has already liked a passed object.
      # 
      # @param [Object] object the object you want to check
      # @return true if `self` likes `object`, false if not
      def likes?(object)
        likes.exists?(:likeable_id => object.id, :likeable_type => object.class.to_s)
      end
      
      # Destroys a Recommendable::Like currently associating `self` with `object`
      #
      # @param [Object] object the object you want to remove from `self`'s likes
      # @return true if `object` is unliked, nil if nothing happened
      def unlike(object)
        if likes.where(:likeable_id => object.id, :likeable_type => object.class.to_s).first.try(:destroy)
          Resque.enqueue RecommendationRefresher, self.id
          true
        end
      end
      
      # Get a list of records that `self` currently likes
      
      # @return [Array] an array of ActiveRecord objects that `self` has liked
      def liked_objects
        likes.map {|like| like.likeable}
      end
      
      # Get a list of Recommendable::Likes with a `#likeable_type` of the passed
      # class.
      #
      # @param [Class, String, Symbol] klass the class for which you would like to
      # return `self`'s likes. Can be the class constant, or a String/Symbol
      # representation of the class name.
      # @note You should not need to use this method. (see {#liked_objects_for})
      def likes_for(klass)
        likes.where(:likeable_type => klassify(klass).to_s)
      end
      
      # Get a list of records belonging to a passed class that `self` currently
      # likes.
      #
      # @param [Class, String, Symbol] klass the class of records. Can be the
      # class constant, or a String/Symbol representation of the class name.
      # @return [Array] an array of ActiveRecord objects that `self` has liked
      # belonging to `klass`
      def liked_objects_for(klass)
        klassify(klass).find likes_for(klass).map(&:likeable_id)
      end
    end
    
    module DislikeMethods
      # Creates a Recommendable::Dislike to associate self to a passed object. If
      # `self` is currently found to have liked `object`, the corresponding
      # Recommendable::Like will be destroyed.
      #
      # @param [Object] object the object you want `self` to dislike.
      # @return true if `object` has been disliked
      # @raise [RecordNotRecommendableError] if you have not declared the passed
      # object's model to `act_as_recommendable`
      def dislike(object)
        raise RecordNotRecommendableError unless Recommendable.recommendable_classes.include?(object.class)
        unlike(object) if likes?(object)
        Recommendable.redis.zrem "#{self.class}:#{id}:predictions", "#{object.class}:#{object.id}"
        dislikes.create!(:dislikeable_id => object.id, :dislikeable_type => object.class.to_s)
        Resque.enqueue RecommendationRefresher, self.id
        true
      end
      
      # Checks to see if `self` has already disliked a passed object.
      # 
      # @param [Object] object the object you want to check
      # @return true if `self` dislikes `object`, false if not
      def dislikes?(object)
        dislikes.exists?(:dislikeable_id => object.id, :dislikeable_type => object.class.to_s)
      end
      
      # Destroys a Recommendable::Dislike currently associating `self` with `object`
      #
      # @param [Object] object the object you want to remove from `self`'s dislikes
      # @return true if `object` is removed from `self`'s dislikes, nil if nothing happened
      def undislike(object)
        if dislikes.where(:dislikeable_id => object.id, :dislikeable_type => object.class.to_s).first.try(:destroy)
          Resque.enqueue RecommendationRefresher, self.id
          true
        end
      end
      
      # Get a list of records that `self` currently dislikes
      
      # @return [Array] an array of ActiveRecord objects that `self` has disliked
      def disliked_objects
        dislikes.map {|dislike| dislike.dislikeable}
      end
      
      # Get a list of Recommendable::Dislikes with a `#dislikeable_type` of the
      # passed class.
      #
      # @param [Class, String, Symbol] klass the class for which you would like to
      # return `self`'s dislikes. Can be the class constant, or a String/Symbol
      # representation of the class name.
      # @note You should not need to use this method. (see {#disliked_objects_for})
      def dislikes_for(klass)
        dislikes.where(:dislikeable_type => klassify(klass).to_s)
      end
      
      # Get a list of records belonging to a passed class that `self` currently
      # dislikes.
      #
      # @param [Class, String, Symbol] klass the class of records. Can be the
      # class constant, or a String/Symbol representation of the class name.
      # @return [Array] an array of ActiveRecord objects that `self` has disliked
      # belonging to `klass`
      def disliked_objects_for(klass)
        klassify(klass).find dislikes_for(klass).map(&:dislikeable_id)
      end
    end
    
    module IgnoreMethods
      # Creates a Recommendable::Ignore to associate self to a passed object. If
      # `self` is currently found to have liked or disliked`object`, the
      # corresponding Recommendable::Like or Recommendable::Dislike will be
      # destroyed.
      #
      # @param [Object] object the object you want `self` to ignore.
      # @return true if `object` has been ignored
      # @raise [RecordNotRecommendableError] if you have not declared the passed
      # object's model to `act_as_recommendable`
      def ignore(object)
        raise RecordNotRecommendableError unless Recommendable.recommendable_classes.include?(object.class)
        unlike(object) if likes?(object) || undislike(object) if dislikes?(object)
        Recommendable.redis.zrem "#{self.class}:#{id}:predictions", "#{object.class}:#{object.id}"
        ignores.create!(:ignoreable_id => object.id, :ignoreable_type => object.class.to_s)
        Resque.enqueue RecommendationRefresher, self.id
        true
      end
      
      # Checks to see if `self` has already ignored a passed object.
      # 
      # @param [Object] object the object you want to check
      # @return true if `self` has ignored `object`, false if not
      def has_ignored?(object)
        ignores.exists?(:ignoreable_id => object.id, :ignoreable_type => object.class.to_s)
      end
      
      # Destroys a Recommendable::Ignore currently associating `self` with `object`
      #
      # @param [Object] object the object you want to remove from `self`'s ignores
      # @return true if `object` is removed from `self`'s ignores, nil if nothing happened
      def unignore(object)
        if ignores.where(:ignoreable_id => object.id, :ignoreable_type => object.class.to_s).first.try(:destroy)
          Resque.enqueue RecommendationRefresher, self.id
          true
        end
      end
      
      # Get a list of records that `self` is currently ignoring
      
      # @return [Array] an array of ActiveRecord objects that `self` has ignored
      def ignored_objects
        ignores.map {|ignore| ignore.ignoreable}
      end
      
      # Get a list of Recommendable::Ignores with a `#ignoreable_type` of the
      # passed class.
      #
      # @param [Class, String, Symbol] klass the class for which you would like to
      # return `self`'s ignores. Can be the class constant, or a String/Symbol
      # representation of the class name.
      # @note You should not need to use this method. (see {#ignored_objects_for})
      def ignores_for(klass)
        ignores.where(:ignoreable_type => klassify(klass).to_s)
      end
      
      # Get a list of records belonging to a passed class that `self` is 
      # currently ignoring.
      #
      # @param [Class, String, Symbol] klass the class of records. Can be the
      # class constant, or a String/Symbol representation of the class name.
      # @return [Array] an array of ActiveRecord objects that `self` has ignored
      # belonging to `klass`
      def ignored_objects_for(klass)
        klassify(klass).find ignores_for(klass).map(&:ignoreable_id)
      end
    end
    
    module RecommendationMethods
      # Checks to see if `self` has already liked or disliked a passed object.
      # 
      # @param [Object] object the object you want to check
      # @return true if `self` has liked or disliked `object`, false if not
      def has_rated?(object)
        likes?(object) || dislikes?(object)
      end
      
      # Checks to see if `self` has liked or disliked any objects yet.
      # 
      # @return true if `self` has liked or disliked anything, false if not
      def has_rated_anything?
        likes.count > 0 || dislikes.count > 0
      end
      
      # Checks how similar a passed rater is with `self`. This method calculates
      # a numeric similarity value that can fall between -1.0 and 1.0. A value of
      # 1.0 indicates that `rater` has the exact same likes and dislikes as `self`
      # while a value of -1.0 indicates that `rater` dislikes every object that `self`
      # likes and likes every object that `self` dislikes. A value of 0.0 would
      # indicate that the two users share no likes or dislikes.
      #
      # @param [Object] rater an ActiveRecord object declared to `act_as_recommendable_to`
      # @return [Float] the numeric similarity between `self` and `rater`
      # @note The returned value relies on which user the method is called on. 
      # current_user.similarity_with(rater) will not equal
      # rater.similarity_with(current_user) unless their sets of likes and dislikes
      # are identical. current_user.similarity_with(rater) will return 1.0 even if
      # `rater` has several likes/dislikes that `current_user` does not.
      def similarity_with(rater)
        rater.create_recommended_to_sets
        agreements = common_likes_with(rater).size + common_dislikes(rater).size
        disagreements = disagreements_with(rater).size
        
        similarity = (agreements - disagreements).to_f / (likes.count + dislikes)
        rater.destroy_recommended_to_sets
        
        return similarity
      end
      
      # Makes a call to Redis and intersects the sets of likes belonging to `self`
      # and `rater`.
      #
      # @param [Object] rater the person whose set of likes you wish to intersect
      # with that of `self`
      # @param [Hash] options the options for this intersection
      # @option options [Class, String, Symbol] :class ('nil') Restrict the intersection
      # to a single recommendable type. By default, all recomendable types are
      # considered
      # @return [Array] An array of strings from Redis in the form of "#{likeable_type}:#{id}"
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
      
      # Makes a call to Redis and intersects the sets of dislikes belonging to
      # `self` and `rater`.
      #
      # @param [Object] rater the person whose set of dislikes you wish to
      # intersect with that of `self`
      # @param [Hash] options the options for this intersection
      # @option options [Class, String, Symbol] :class ('nil') Restrict the intersection
      # to a single recommendable type. By default, all recomendable types are
      # considered
      # @return [Array] An array of strings from Redis in the form of 
      # #{dislikeable_type}:#{id}"
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
      
      # Makes a call to Redis and intersects `self`'s set of likes with `rater`'s
      # set of dislikes and vise versa. The idea here is that if `self` likes
      # an object that `rater` dislikes, it is a disagreement and should count
      # negatively towards their similarity.
      #
      # @param [Object] rater the person whose sets you wish to intersect with
      # those of `self`
      # @param [Hash] options the options for this intersection
      # @option options [Class, String, Symbol] :class ('nil') Restrict the
      # intersections to a single recommendable type. By default,
      # all recomendable types are considered
      # @return [Array] An array of strings from Redis in the form of 
      # #{recommendable_type}:#{id}"
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
      
      # Get a list of raters that have been found to be the most similar to
      # `self`. They are sorted in a descending fashion with the most similar
      # rater in the first index.
      #
      # @param [Hash] options the options for this query
      # @option options [Fixnum] :count (10) The number of raters to return
      # @return [Array] An array of instances of your user class
      def similar_raters(options)
        defaults = { :count => 10 }
        options = defaults.merge(options)
        
        rater_ids = Recommendable.redis.zrevrange "#{self.class}:#{id}:similarities", 0, options[:count] - 1
        Recommendable.user_class.find rater_ids, order: "field(id, #{ids.join(',')})"
      end
      
      # Used internally to update the similarity values between `self` and all
      # other users. This is called in the Resque job to refresh recommendations.
      #
      # @note Do not call this method directly. Seriously, don't do it.
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
      
      # Used internally to update `self`'s prediction values across all
      # recommendable types. This is called in the Resque job to refresh
      # recommendations.
      #
      # @note Do not call this method directly. Seriously, don't do it.
      def update_recommendations
        Recommendable.recommendable_classes.each do |klass|
          update_predictions_for(klass)
        end
      end
      
      # Used internally to update `self`'s prediction values across a single
      # recommendable type. Convenience method for {#update_recommendations}
      #
      # @param [Class] klass the recommendable type to update predictions for
      # @note Do not call this method directly. Seriously, don't do it.
      def update_recommendations_for(klass)
        klass.find_each do |object|
          unless has_rated?(object)
            prediction = predict(object)
            Recommendable.redis.zadd "#{self.class}:#{id}:predictions:#{object.class}", prediction, "#{object.class}:#{object.id}" if prediction
          end
        end
      end
      
      # Get a list of recommendations for `self`. The whole point of this gem!
      # Recommendations are returned in a descending order with the first index
      # being the object that `self` has been found most likely to enjoy.
      #
      # @param [Hash] options the options for returning this list
      # @option options [Fixnum] :count (10) the number of recommendations to get
      # @return [Array] an array of ActiveRecord objects that are recommendable
      def recommendations(options = {})
        defaults = { :count => 10 }
        options = defaults.merge options

        unioned_predictions = "#{self.class}:#{id}:predictions"
        Recommendable.redis.zunionstore unioned_predictions, Recommendable.recommendable_classes.map {|klass| "#{self.class}:#{id}:predictions:#{klass}"}
        return [] if likes.count + dislikes.count == 0 || Recommendable.redis.zcard(unioned_predictions) == 0
        
        recommendations = Recommendable.redis.zrevrange(unioned_predictions, 0, options[:count]).map do |object|
          object.klass.find(object.likeable_id)
        end
        
        Recommendable.redis.del unioned_predictions
        recommendations
      end
      
      # Get a list of recommendations for `self` on a single recommendable type.
      # Recommendations are returned in a descending order with the first index
      # being the object that `self` has been found most likely to enjoy.
      #
      # @param [Class, String, Symbol] klass the class to receive recommendations
      # for. Can be the class constant, or a String/Symbol representation of the
      # class name.
      # @param [Hash] options the options for returning this list
      # @option options [Fixnum] :count (10) the number of recommendations to get
      # @return [Array] an array of ActiveRecord objects that are recommendable
      def recommendations_for(klass, options = {})
        defaults = { :count => 10 }
        options = defaults.merge options
        
        recommendations = []
        return recommendations if likes_for(klass).count + dislikes_for(klass).count == 0 || Recommendable.redis.zcard("#{self.class}:#{id}:predictions:#{klass}") == 0
      
        until predictions.size == options[:count]
          i += 1
          object = klassify(klass).find(Recommendable.redis.zrevrange("#{self.class}:#{id}:predictions:#{klass}", i, i).first.split(":")[1])
          recommendations << object unless has_ignored?(object)
        end
      
        return recommendations
      end
      
      # Predict how likely it is that `self` will like a passed in object. This
      # probability is not based on percentage. 0.0 indicates that `self` will
      # neither like nor dislike the passed object. Values that approach Infinity
      # indicate a rising probability of liking the passed object while values
      # approaching -Infinity indicate a rising probability of disliking the
      # passed object.
      #
      # @param [Object] object the object to check the likeliness of liking
      # @return [Float] the probability that `self` will like `object`
      def predict(object)
        liked_by, disliked_by = object.create_recommendable_sets
        rated_by = Recommendable.redis.scard(liked_by) + Recommendable.redis.scard(disliked_by)
        sum = 0.0
        prediction = 0.0
      
        Recommendable.redis.smembers(liked_by).inject(sum) {|r, sum| sum += Recommendable.redis.zscore("#{self.class}:#{id}:similarities", r) }
        Recommendable.redis.smembers(disliked_by).inject(sum) {|r, sum| sum -= Recommendable.redis.zscore("#{self.class}:#{id}:similarities", r) }
      
        prediction = similarity_sum / rated_by.to_f
        
        object.destroy_recommendable_sets
        
        return prediction
      end
      
      # Return the value calculated by {#predict} on `self` for a passed object.
      #
      # @param [Object] object the object to fetch the probability for
      # @return [Float] the likelihood of `self` liking the passed object
      def probability_of_liking(object)
        Recommendable.redis.zscore "#{self.class}:#{id}:predictions:#{object.class}", "#{object.class}:#{object.id}"
      end
      
      # Return the negation of the value calculated by {#predict} on `self`
      # for a passed object.
      #
      # @param [Object] object the object to fetch the probability for
      # @return [Float] the likelihood of `self` disliking the passed object
      # @see #probability of liking
      def probability_of_disliking(object)
        -probability_of_liking(object)
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
