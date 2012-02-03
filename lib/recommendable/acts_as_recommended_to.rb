require 'active_support/concern'

module Recommendable
  module ActsAsRecommendedTo
    extend ActiveSupport::Concern
    
    module ClassMethods
      def acts_as_recommended_to
        class_eval do
          has_many :likes, :class_name => "Recommendable::Like", :dependent => :destroy
          has_many :dislikes, :class_name => "Recommendable::Dislike", :dependent => :destroy
          has_many :ignores, :class_name => "Recommendable::Ignore", :dependent => :destroy
          has_many :stashed_items, :class_name => "Recommendable::StashedItem", :dependent => :destroy
          
          include LikeMethods
          include DislikeMethods
          include StashMethods
          include IgnoreMethods
          include RecommendationMethods

          def self.acts_as_recommended_to? ; true ; end

          private :likes, :dislikes, :ignores, :stashed_items
        end
      end

      def acts_as_recommended_to? ; false ; end
    end

    # Instance method.
    def can_rate? ; self.class.acts_as_recommended_to? ; end

    module LikeMethods
      # Creates a Recommendable::Like to associate self to a passed object. If
      # self is currently found to have disliked object, the corresponding
      # Recommendable::Dislike will be destroyed. It will also be removed from
      # the user's stash or ignores.
      #
      # @param [Object] object the object you want self to like.
      # @return true if object has been liked
      # @raise [RecordNotRecommendableError] if you have not declared the passed object's model to `act_as_recommendable`
      def like(object)
        raise RecordNotRecommendableError unless object.recommendable?
        return if likes?(object)
        undislike(object)
        unstash(object)
        unignore(object)
        unpredict(object)
        likes.create!(:likeable_id => object.id, :likeable_type => object.class.to_s)
        Resque.enqueue RecommendationRefresher, self.id
        true
      end
      
      # Checks to see if self has already liked a passed object.
      # 
      # @param [Object] object the object you want to check
      # @return true if self likes object, false if not
      def likes?(object)
        likes.exists?(:likeable_id => object.id, :likeable_type => object.class.to_s)
      end
      
      # Destroys a Recommendable::Like currently associating self with object
      #
      # @param [Object] object the object you want to remove from self's likes
      # @return true if object is unliked, nil if nothing happened
      def unlike(object)
        if likes.where(:likeable_id => object.id, :likeable_type => object.class.to_s).first.try(:destroy)
          Resque.enqueue RecommendationRefresher, self.id
          true
        end
      end
      
      # Get a list of records that self currently likes
      
      # @return [Array] an array of ActiveRecord objects that self has liked
      def liked
        likes.map {|like| like.likeable}
      end

      alias_method :liked_records, :liked
      
      # Get a list of Recommendable::Likes with a `#likeable_type` of the passed
      # class.
      #
      # @param [Class, String, Symbol] klass the class for which you would like to return self's likes. Can be the class constant, or a String/Symbol representation of the class name.
      # @note You should not need to use this method. (see {#liked_for})
      # @private
      def likes_for(klass)
        likes.where(:likeable_type => klassify(klass).to_s)
      end
      
      # Get a list of records belonging to a passed class that self currently
      # likes.
      #
      # @param [Class, String, Symbol] klass the class of records. Can be the class constant, or a String/Symbol representation of the class name.
      # @return [Array] an array of ActiveRecord objects that self has liked belonging to klass
      def liked_for(klass)
        klassify(klass).find likes_for(klass).map(&:likeable_id)
      end

      alias_method :liked_records_for, :liked_for
      private :likes_for
    end
    
    module DislikeMethods
      # Creates a Recommendable::Dislike to associate self to a passed object. If
      # self is currently found to have liked object, the corresponding
      # Recommendable::Like will be destroyed. It will also be removed from the
      # user's stash or list of ignores.
      #
      # @param [Object] object the object you want self to dislike.
      # @return true if object has been disliked
      # @raise [RecordNotRecommendableError] if you have not declared the passed object's model to `act_as_recommendable`
      def dislike(object)
        raise RecordNotRecommendableError unless object.recommendable?
        return if dislikes?(object)
        unlike(object)
        unstash(object)
        unignore(object)
        unpredict(object)
        dislikes.create!(:dislikeable_id => object.id, :dislikeable_type => object.class.to_s)
        Resque.enqueue RecommendationRefresher, self.id
        true
      end
      
      # Checks to see if self has already disliked a passed object.
      # 
      # @param [Object] object the object you want to check
      # @return true if self dislikes object, false if not
      def dislikes?(object)
        dislikes.exists?(:dislikeable_id => object.id, :dislikeable_type => object.class.to_s)
      end
      
      # Destroys a Recommendable::Dislike currently associating self with object
      #
      # @param [Object] object the object you want to remove from self's dislikes
      # @return true if object is removed from self's dislikes, nil if nothing happened
      def undislike(object)
        if dislikes.where(:dislikeable_id => object.id, :dislikeable_type => object.class.to_s).first.try(:destroy)
          Resque.enqueue RecommendationRefresher, self.id
          true
        end
      end
      
      # Get a list of records that self currently dislikes
      
      # @return [Array] an array of ActiveRecord objects that self has disliked
      def disliked
        dislikes.map {|dislike| dislike.dislikeable}
      end

      alias_method :disliked_records, :disliked
      
      # Get a list of Recommendable::Dislikes with a `#dislikeable_type` of the
      # passed class.
      #
      # @param [Class, String, Symbol] klass the class for which you would like to return self's dislikes. Can be the class constant, or a String/Symbol representation of the class name.
      # @note You should not need to use this method. (see {#disliked_for})
      # @private
      def dislikes_for(klass)
        dislikes.where(:dislikeable_type => klassify(klass).to_s)
      end
      
      # Get a list of records belonging to a passed class that self currently
      # dislikes.
      #
      # @param [Class, String, Symbol] klass the class of records. Can be the class constant, or a String/Symbol representation of the class name.
      # @return [Array] an array of ActiveRecord objects that self has disliked belonging to klass
      def disliked_for(klass)
        klassify(klass).find dislikes_for(klass).map(&:dislikeable_id)
      end

      alias_method :disliked_records_for, :disliked_for
      private :dislikes_for
    end

    module StashMethods
      # Creates a Recommendable::StashedItem to associate self to a passed object.
      # This will remove the item from this user's recommendations.
      # If self is currently found to have liked or disliked the object, nothing
      # will happen. It will, however, be unignored.
      #
      # @param [Object] object the object you want self to stash.
      # @return true if object has been stashed
      # @raise [RecordNotRecommendableError] if you have not declared the passed object's model to `act_as_recommendable`
      def stash(object)
        raise RecordNotRecommendableError unless object.recommendable?
        return if has_rated?(object) || has_stashed?(object)
        unignore(object)
        unpredict(object)
        stashed_items.create!(:stashable_id => object.id, :stashable_type => object.class.to_s)
        true
      end
      
      # Checks to see if self has already stashed a passed object for later.
      # 
      # @param [Object] object the object you want to check
      # @return true if self has stashed object, false if not
      def has_stashed?(object)
        stashed_items.exists?(:stashable_id => object.id, :stashable_type => object.class.to_s)
      end
      
      # Destroys a Recommendable::StashedItem currently associating self with object
      #
      # @param [Object] object the object you want to remove from self's stash
      # @return true if object is stashed, nil if nothing happened
      def unstash(object)
        true if stashed_items.where(:stashable_id => object.id, :stashable_type => object.class.to_s).first.try(:destroy)
      end
      
      # Get a list of records that self has currently stashed for later
      
      # @return [Array] an array of ActiveRecord objects that self has stashed
      def stashed
        stashed_items.map {|item| item.stashable}
      end

      alias_method :stashed_records, :stashed
      
      # Get a list of Recommendable::StashedItems with a stashable_type of the
      # passed class.
      #
      # @param [Class, String, Symbol] klass the class for which you would like to return self's stashed items. Can be the class constant, or a String/Symbol representation of the class name.
      # @note You should not need to use this method. (see {#stashed_for})
      # @private
      def stash_for(klass)
        stashed_items.where(:stashable_type => klassify(klass).to_s)
      end
      
      # Get a list of records belonging to a passed class that self currently
      # has stashed away for later.
      #
      # @param [Class, String, Symbol] klass the class of records. Can be the class constant, or a String/Symbol representation of the class name.
      # @return [Array] an array of ActiveRecord objects that self has stashed belonging to klass
      def stashed_for(klass)
        klassify(klass).find stash_for(klass).map(&:stashable_id)
      end

      alias_method :stashed_records_for, :stashed_for
      private :stash_for
    end
    
    module IgnoreMethods
      # Creates a Recommendable::Ignore to associate self to a passed object. If
      # self is currently found to have liked or dislikedobject, the
      # corresponding Recommendable::Like or Recommendable::Dislike will be
      # destroyed.
      #
      # @param [Object] object the object you want self to ignore.
      # @return true if object has been ignored
      # @raise [RecordNotRecommendableError] if you have not declared the passed object's model to `act_as_recommendable`
      def ignore(object)
        raise RecordNotRecommendableError unless object.recommendable?
        return if has_ignored?(object)
        unlike(object)
        undislike(object)
        unstash(object)
        unpredict(object)
        ignores.create!(:ignoreable_id => object.id, :ignoreable_type => object.class.to_s)
        true
      end
      
      # Checks to see if self has already ignored a passed object.
      # 
      # @param [Object] object the object you want to check
      # @return true if self has ignored object, false if not
      def has_ignored?(object)
        ignores.exists?(:ignoreable_id => object.id, :ignoreable_type => object.class.to_s)
      end
      
      # Destroys a Recommendable::Ignore currently associating self with object
      #
      # @param [Object] object the object you want to remove from self's ignores
      # @return true if object is removed from self's ignores, nil if nothing happened
      def unignore(object)
        true if ignores.where(:ignoreable_id => object.id, :ignoreable_type => object.class.to_s).first.try(:destroy)
      end
      
      # Get a list of records that self is currently ignoring
      
      # @return [Array] an array of ActiveRecord objects that self has ignored
      def ignored
        ignores.map {|ignore| ignore.ignoreable}
      end

      alias_method :ignored_records, :ignored
      
      # Get a list of Recommendable::Ignores with a `#ignoreable_type` of the
      # passed class.
      #
      # @param [Class, String, Symbol] klass the class for which you would like to return self's ignores. Can be the class constant, or a String/Symbol representation of the class name.
      # @note You should not need to use this method. (see {#ignored_for})
      # @private
      def ignores_for(klass)
        ignores.where(:ignoreable_type => klassify(klass).to_s)
      end
      
      # Get a list of records belonging to a passed class that self is 
      # currently ignoring.
      #
      # @param [Class, String, Symbol] klass the class of records. Can be the class constant, or a String/Symbol representation of the class name.
      # @return [Array] an array of ActiveRecord objects that self has ignored belonging to klass
      def ignored_for(klass)
        klassify(klass).find ignores_for(klass).map(&:ignoreable_id)
      end

      alias_method :ignored_records_for, :ignored_for
      private :ignores_for
    end
    
    module RecommendationMethods
      def self.acts_as_recommended_to? ; true ; end

      def can_receive_recommendations? ; self.class.acts_as_recommended_to? ; end

      # Checks to see if self has already liked or disliked a passed object.
      # 
      # @param [Object] object the object you want to check
      # @return true if self has liked or disliked object, false if not
      def has_rated?(object)
        likes?(object) || dislikes?(object)
      end
      
      # Checks to see if self has liked or disliked any objects yet.
      # 
      # @return true if self has liked or disliked anything, false if not
      def has_rated_anything?
        likes.count > 0 || dislikes.count > 0
      end
      
      # Get a list of raters that have been found to be the most similar to
      # self. They are sorted in a descending fashion with the most similar
      # rater in the first index.
      #
      # @param [Hash] options the options for this query
      # @option options [Fixnum] :count (10) The number of raters to return
      # @return [Array] An array of instances of your user class
      def similar_raters(options = {})
        defaults = { :count => 10 }
        options = defaults.merge(options)
        
        rater_ids = Recommendable.redis.zrevrange(similarity_set, 0, options[:count] - 1).map!(&:to_i)
        raters = Recommendable.user_class.where("ID IN (?)", rater_ids)
        
        # The query loses the ordering, so...
        return raters.sort do |x, y|
          rater_ids.index(x.id) <=> rater_ids.index(y.id)
        end
      end
      
      # Get a list of recommendations for self. The whole point of this gem!
      # Recommendations are returned in a descending order with the first index
      # being the object that self has been found most likely to enjoy.
      #
      # @param [Hash] options the options for returning this list
      # @option options [Fixnum] :count (10) the number of recommendations to get
      # @return [Array] an array of ActiveRecord objects that are recommendable
      def recommendations(options = {})
        defaults = { :count => 10 }
        options = defaults.merge options

        unioned_predictions = "#{self.class}:#{id}:predictions"
        Recommendable.redis.zunionstore unioned_predictions, Recommendable.recommendable_classes.map {|klass| predictions_set_for(klass)}
        return [] if likes.count + dislikes.count == 0 || Recommendable.redis.zcard(unioned_predictions) == 0
        
        recommendations = Recommendable.redis.zrevrange(unioned_predictions, 0, options[:count]).map do |object|
          klass, id = object.split(":")
          klass.constantize.find(id)
        end
        
        Recommendable.redis.del unioned_predictions
        return recommendations
      end
      
      # Get a list of recommendations for self on a single recommendable type.
      # Recommendations are returned in a descending order with the first index
      # being the object that self has been found most likely to enjoy.
      #
      # @param [Class, String, Symbol] klass the class to receive recommendations for. Can be the class constant, or a String/Symbol representation of the class name.
      # @param [Hash] options the options for returning this list
      # @option options [Fixnum] :count (10) the number of recommendations to get
      # @return [Array] an array of ActiveRecord objects that are recommendable
      def recommendations_for(klass, options = {})
        defaults = { :count => 10 }
        options = defaults.merge options
        
        recommendations = []
        return recommendations if likes_for(klass).count + dislikes_for(klass).count == 0 || Recommendable.redis.zcard(predictions_set_for(klass)) == 0
      
        i = 0
        until recommendations.size == options[:count]
          prediction = Recommendable.redis.zrevrange(predictions_set_for(klass), i, i).first
          return recommendations unless prediction # User might not have enough recommendations to return
          
          object = klassify(klass).find(prediction.split(":")[1])
          recommendations << object unless has_ignored?(object)
          i += 1
        end
      
        return recommendations
      end
      
      # Return the value calculated by {#predict} on self for a passed object.
      #
      # @param [Object] object the object to fetch the probability for
      # @return [Float] the likelihood of self liking the passed object
      def probability_of_liking(object)
        Recommendable.redis.zscore predictions_set_for(object.class), object.redis_key
      end
      
      # Return the negation of the value calculated by {#predict} on self
      # for a passed object.
      #
      # @param [Object] object the object to fetch the probability for
      # @return [Float] the likelihood of self disliking the passed object
      # @see #probability of liking
      def probability_of_disliking(object)
        -probability_of_liking(object)
      end
      
      # Checks how similar a passed rater is with self. This method calculates
      # a numeric similarity value that can fall between -1.0 and 1.0. A value of
      # 1.0 indicates that rater has the exact same likes and dislikes as self
      # while a value of -1.0 indicates that rater dislikes every object that self
      # likes and likes every object that self dislikes. A value of 0.0 would
      # indicate that the two users share no likes or dislikes.
      #
      # @param [Object] rater an ActiveRecord object declared to `act_as_recommendable_to`
      # @return [Float] the numeric similarity between self and rater
      # @note The returned value relies on which user the method is called on. current_user.similarity_with(rater) will not equal rater.similarity_with(current_user) unless their sets of likes and dislikes are identical. current_user.similarity_with(rater) will return 1.0 even if rater has several likes/dislikes that `current_user` does not.
      # @private
      def similarity_with(rater)
        return unless rater.can_rate?

        rater.create_recommended_to_sets
        agreements = common_likes_with(rater).size + common_dislikes_with(rater).size
        disagreements = disagreements_with(rater).size
        
        similarity = (agreements - disagreements).to_f / (likes.count + dislikes.count)
        rater.destroy_recommended_to_sets
        
        return similarity
      end
      # Makes a call to Redis and intersects the sets of likes belonging to self
      # and rater.
      #
      # @param [Object] rater the person whose set of likes you wish to intersect with that of self
      # @param [Hash] options the options for this intersection
      # @option options [Class, String, Symbol] :class ('nil') Restrict the intersection to a single recommendable type. By default, all recomendable types are considered
      # @return [Array] An array of strings from Redis in the form of "#{likeable_type}:#{id}"
      # @private
      def common_likes_with(rater, options = {})
        defaults = { :class => nil }
        options = defaults.merge(options)
        
        if options[:class]
          Recommendable.redis.sinter likes_set_for(options[:class]), rater.likes_set_for(options[:class])
        else
          Recommendable.recommendable_classes.map do |klass|
            Recommendable.redis.sinter(likes_set_for(klass), rater.likes_set_for(klass)).map {|id| "#{klass}:#{id}"}
          end
        end
      end
      
      # Makes a call to Redis and intersects the sets of dislikes belonging to
      # self and rater.
      #
      # @param [Object] rater the person whose set of dislikes you wish to intersect with that of self
      # @param [Hash] options the options for this intersection
      # @option options [Class, String, Symbol] :class ('nil') Restrict the intersection to a single recommendable type. By default, all recomendable types are considered
      # @return [Array] An array of strings from Redis in the form of #{dislikeable_type}:#{id}"
      # @private
      def common_dislikes_with(rater, options = {})
        defaults = { :class => nil }
        options = defaults.merge(options)
        
        if options[:class]
          Recommendable.redis.sinter dislikes_set_for(options[:class]), rater.dislikes_set_for(options[:class])
        else
          Recommendable.recommendable_classes.map do |klass|
            Recommendable.redis.sinter(dislikes_set_for(klass), rater.dislikes_set_for(klass)).map {|id| "#{klass}:#{id}"}
          end
        end
      end
      
      # Makes a call to Redis and intersects self's set of likes with rater's
      # set of dislikes and vise versa. The idea here is that if self likes
      # an object that rater dislikes, it is a disagreement and should count
      # negatively towards their similarity.
      #
      # @param [Object] rater the person whose sets you wish to intersect with those of self
      # @param [Hash] options the options for this intersection
      # @option options [Class, String, Symbol] :class ('nil') Restrict the intersections to a single recommendable type. By default, all recomendable types are considered
      # @return [Array] An array of strings from Redis in the form of #{recommendable_type}:#{id}"
      # @private
      def disagreements_with(rater, options = {})
        defaults = { :class => nil }
        options = defaults.merge(options)
        
        if options[:class]
          Recommendable.redis.sinter(likes_set_for(options[:class]), rater.likes_set_for(options[:class])).size +
          Recommendable.redis.sinter(dislikes_set_for(options[:class]), rater.dislikes_set_for(options[:class])).size
        else
          Recommendable.recommendable_classes.inject(0) do |sum, klass|
            sum += Recommendable.redis.sinter(likes_set_for(klass), rater.likes_set_for(klass)).size
            sum += Recommendable.redis.sinter(dislikes_set_for(klass), rater.dislikes_set_for(klass)).size
          end
        end
      end
      
      # Predict how likely it is that self will like a passed in object. This
      # probability is not based on percentage. 0.0 indicates that self will
      # neither like nor dislike the passed object. Values that approach Infinity
      # indicate a rising probability of liking the passed object while values
      # approaching -Infinity indicate a rising probability of disliking the
      # passed object.
      #
      # @param [Object] object the object to check the likeliness of liking
      # @return [Float] the probability that self will like object
      # @private
      def predict(object)
        liked_by, disliked_by = object.create_recommendable_sets
        rated_by = Recommendable.redis.scard(liked_by) + Recommendable.redis.scard(disliked_by)
        sum = 0.0
        prediction = 0.0
      
        Recommendable.redis.smembers(liked_by).inject(sum) {|sum, r| sum += Recommendable.redis.zscore(similarity_set, r).to_f }
        Recommendable.redis.smembers(disliked_by).inject(sum) {|sum, r| sum -= Recommendable.redis.zscore(similarity_set, r).to_f }
      
        prediction = sum / rated_by.to_f
        
        object.destroy_recommendable_sets
        
        return prediction
      end
      
      # Used internally to update the similarity values between self and all
      # other users. This is called in the Resque job to refresh recommendations.
      #
      # @private
      def update_similarities
        return unless has_rated_anything?
        self.create_recommended_to_sets
        
        Recommendable.user_class.find_each do |rater|
          next if self == rater
          Recommendable.redis.zadd similarity_set, similarity_with(rater), "#{rater.id}"
        end
        
        self.destroy_recommended_to_sets
      end
      
      # Used internally to update self's prediction values across all
      # recommendable types. This is called in the Resque job to refresh
      # recommendations.
      #
      # @private
      def update_recommendations
        Recommendable.recommendable_classes.each do |klass|
          update_recommendations_for(klass)
        end
      end
      
      # Used internally to update self's prediction values across a single
      # recommendable type. Convenience method for {#update_recommendations}
      #
      # @param [Class] klass the recommendable type to update predictions for
      # @private
      def update_recommendations_for(klass)
        klass.find_each do |object|
          next if has_rated?(object) || !object.has_been_rated? || has_ignored?(object) || has_stashed?(object)
          prediction = predict(object)
          Recommendable.redis.zadd(predictions_set_for(object.class), prediction, object.redis_key) if prediction
        end
      end

      # @private
      def likes_set_for(klass)
        "#{self.class}:#{id}:likes:#{klass}"
      end
      
      # @private
      def dislikes_set_for(klass)
        "#{self.class}:#{id}:dislikes:#{klass}"
      end
      
      # @private
      def similarity_set
        "#{self.class}:#{id}:similarities"
      end
      
      # @private
      def predictions_set_for(klass)
        "#{self.class}:#{id}:predictions:#{klass}"
      end
      
      # @private
      def unpredict(object)
        Recommendable.redis.zrem predictions_set_for(object.class), "#{object.class}:#{object.id}"
      end
      
      # Used for setup purposes. Creates and populates sets in redis containing
      # self's likes and dislikes.
      # @private
      def create_recommended_to_sets
        Recommendable.recommendable_classes.each do |klass|
          likes_for(klass).each {|like| Recommendable.redis.sadd likes_set_for(klass), like.likeable_id }
          dislikes_for(klass).each {|dislike| Recommendable.redis.sadd dislikes_set_for(klass), dislike.dislikeable_id }
        end
      end
      
      # Used for teardown purposes. Destroys the redis sets containing self's
      # likes and dislikes, as they are only used during the process of
      # updating recommendations and similarity values.
      # @private
      def destroy_recommended_to_sets
        Recommendable.recommendable_classes.each do |klass|
          Recommendable.redis.del likes_set_for(klass)
          Recommendable.redis.del dislikes_set_for(klass)
        end
      end

      private :likes_set_for, :dislikes_set_for, :similarity_set,
              :predictions_set_for, :unpredict, :create_recommended_to_sets,
              :destroy_recommended_to_sets, :update_recommendations_for,
              :update_recommendations, :update_similarities, :similarity_with,
              :predict, :common_likes_with, :common_dislikes_with, :disagreements_with
    end
  end
end

def klassify(klass)
  (klass.is_a?(String) || klass.is_a?(Symbol)) ? klass.to_s.camelize.constantize : klass
end
