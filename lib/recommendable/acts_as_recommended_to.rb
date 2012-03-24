require 'active_support/concern'

module Recommendable
  module ActsAsRecommendedTo
    extend ActiveSupport::Concern
    
    module ClassMethods
      def recommends(*things)
        acts_as_recommended_to
        things.each { |thing| thing.to_s.classify.constantize.acts_as_recommendable }
      end

      def acts_as_recommended_to
        class_eval do
          Recommendable.user_class = self
          
          has_many :likes, :class_name => "Recommendable::Like", :dependent => :destroy, :foreign_key => :user_id
          has_many :dislikes, :class_name => "Recommendable::Dislike", :dependent => :destroy, :foreign_key => :user_id
          has_many :ignores, :class_name => "Recommendable::Ignore", :dependent => :destroy, :foreign_key => :user_id
          has_many :stashed_items, :class_name => "Recommendable::StashedItem", :dependent => :destroy, :foreign_key => :user_id
          
          include LikeMethods
          include DislikeMethods
          include StashMethods
          include IgnoreMethods
          include RecommendationMethods

          def method_missing(method, *args, &block)
            if method.to_s =~ /(liked|disliked|ignored|stashed|recommended)_(.+)/
              begin
                super unless $2.classify.constantize.acts_as_recommendable?

                self.send "#{$1}_for", $2.classify.constantize
              rescue NameError
                super
              end
            else
              super
            end
          end

          def respond_to?(method)
            if method.to_s =~ /(liked|disliked|ignored|stashed|recommended)_(.+)/
              begin
                $2.classify.constantize.acts_as_recommendable?
              rescue NameError
                false
              end
            else
              super
            end
          end

          private :likes, :dislikes, :ignores, :stashed_items
        end
      end
    end

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
        return if likes? object
        completely_unrecommend object
        likes.create! :likeable_id => object.id, :likeable_type => object.class.to_s
        Resque.enqueue RecommendationRefresher, self.id
        true
      end
      
      # Checks to see if self has already liked a passed object.
      # 
      # @param [Object] object the object you want to check
      # @return true if self likes object, false if not
      def likes?(object)
        likes.exists? :likeable_id => object.id, :likeable_type => object.class.to_s
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
        Recommendable.recommendable_classes.flat_map { |klass| liked_for klass }
      end

      private

      # Get a list of records belonging to a passed class that self currently
      # likes.
      #
      # @param [Class, String, Symbol] klass the class of records. Can be the class constant, or a String/Symbol representation of the class name.
      # @return [Array] an array of ActiveRecord objects that self has liked belonging to klass
      def liked_for(klass)
        likes.where(:likeable_type => klass).includes(:likeable).map(&:likeable)
      end

      # Get a list of Recommendable::Likes with a `#likeable_type` of the passed
      # class.
      #
      # @param [Class, String, Symbol] klass the class for which you would like to return self's likes. Can be the class constant, or a String/Symbol representation of the class name.
      # @note You should not need to use this method. (see {#liked_for})
      # @private
      def likes_for(klass)
        likes.where :likeable_type => klass.to_s.classify
      end
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
        return if dislikes? object
        completely_unrecommend object
        dislikes.create! :dislikeable_id => object.id, :dislikeable_type => object.class.to_s
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
        Recommendable.recommendable_classes.flat_map { |klass| disliked_for(klass) }
      end

      private

      # Get a list of records belonging to a passed class that self currently
      # dislikes.
      #
      # @param [Class, String, Symbol] klass the class of records. Can be the class constant, or a String/Symbol representation of the class name.
      # @return [Array] an array of ActiveRecord objects that self has disliked belonging to klass
      def disliked_for(klass)
        dislikes.where(:dislikeable_type => klass).includes(:dislikeable).map(&:dislikeable)
      end
      
      # Get a list of Recommendable::Dislikes with a `#dislikeable_type` of the
      # passed class.
      #
      # @param [Class, String, Symbol] klass the class for which you would like to return self's dislikes. Can be the class constant, or a String/Symbol representation of the class name.
      # @note You should not need to use this method. (see {#disliked_for})
      # @private
      def dislikes_for(klass)
        dislikes.where :dislikeable_type => klass.to_s.classify
      end
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
        return if rated?(object) || stashed?(object)
        unignore object
        unpredict object
        stashed_items.create! :stashable_id => object.id, :stashable_type => object.class.to_s
        true
      end
      
      # Checks to see if self has already stashed a passed object for later.
      # 
      # @param [Object] object the object you want to check
      # @return true if self has stashed object, false if not
      def stashed?(object)
        stashed_items.exists? :stashable_id => object.id, :stashable_type => object.class.to_s
      end
      
      # Destroys a Recommendable::StashedItem currently associating self with object
      #
      # @param [Object] object the object you want to remove from self's stash
      # @return true if object is stashed, nil if nothing happened
      def unstash(object)
        true if stashed_items.where(:stashable_id => object.id, :stashable_type => object.class.to_s).first.try(:destroy)
      end
      
      # Get a list of records that self has currently stashed for later
      #
      # @return [Array] an array of ActiveRecord objects that self has stashed
      def stashed
        Recommendable.recommendable_classes.flat_map { |klass| stashed_for klass }
      end

      private

      # Get a list of records belonging to a passed class that self currently
      # has stashed away for later.
      #
      # @param [Class, String, Symbol] klass the class of records. Can be the class constant, or a String/Symbol representation of the class name.
      # @return [Array] an array of ActiveRecord objects that self has stashed belonging to klass
      def stashed_for(klass)
        stashed_items.where(:stashable_type => klass).includes(:stashable).map(&:stashable)
      end
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
        return if ignored? object
        completely_unrecommend object
        ignores.create! :ignoreable_id => object.id, :ignoreable_type => object.class.to_s
        true
      end
      
      # Checks to see if self has already ignored a passed object.
      # 
      # @param [Object] object the object you want to check
      # @return true if self has ignored object, false if not
      def ignored?(object)
        ignores.exists? :ignoreable_id => object.id, :ignoreable_type => object.class.to_s
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
        Recommendable.recommendable_classes.flat_map { |klass| ignored_for klass }
      end

      private

      # Get a list of records belonging to a passed class that self is 
      # currently ignoring.
      #
      # @param [Class, String, Symbol] klass the class of records. Can be the class constant, or a String/Symbol representation of the class name.
      # @return [Array] an array of ActiveRecord objects that self has ignored belonging to klass
      def ignored_for(klass)
        ignores.where(:ignoreable_type => klass).includes(:ignoreable).map(&:ignoreable)
      end
    end
    
    module RecommendationMethods
      # Checks to see if self has already liked or disliked a passed object.
      # 
      # @param [Object] object the object you want to check
      # @return true if self has liked or disliked object, false if not
      def rated?(object)
        likes?(object) || dislikes?(object)
      end
      
      # Checks to see if self has liked or disliked any objects yet.
      # 
      # @return true if self has liked or disliked anything, false if not
      def rated_anything?
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
        options = defaults.merge options
        
        rater_ids = Recommendable.redis.zrevrange(similarity_set, 0, options[:count] - 1).map(&:to_i)
        raters = Recommendable.user_class.where "ID IN (?)", rater_ids
        
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
        return [] if likes.count + dislikes.count == 0

        unioned_predictions = "#{self.class}:#{id}:predictions"
        Recommendable.redis.zunionstore unioned_predictions, Recommendable.recommendable_classes.map { |klass| predictions_set_for(klass) }
        
        recommendations = Recommendable.redis.zrevrange(unioned_predictions, 0, 10).map do |object|
          klass, id = object.split(":")
          klass.constantize.find(id)
        end
        
        Recommendable.redis.del(unioned_predictions) and return recommendations
      end
      
      # Get a list of 10 recommendations for self on a single recommendable type.
      # Recommendations are returned in a descending order with the first index
      # being the object that self has been found most likely to enjoy.
      #
      # @param [Class, String, Symbol] klass the class to receive recommendations for. Can be the class constant, or a String/Symbol representation of the class name.
      # @return [Array] an array of ActiveRecord objects that are recommendable
      def recommended_for(klass)
        return [] if likes_for(klass).count + dislikes_for(klass).count == 0 || Recommendable.redis.zcard(predictions_set_for(klass)) == 0
      
        recommendations = []
        i = 0
        until recommendations.size == 10
          prediction = Recommendable.redis.zrevrange(predictions_set_for(klass), i, i).first
          return recommendations unless prediction # User might not have enough recommendations to return
          
          object = klass.to_s.classify.constantize.find(prediction.split(":")[1])
          recommendations << object
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
      # @see {#probability_of_liking}
      def probability_of_disliking(object)
        -probability_of_liking(object)
      end
      
      # Makes a call to Redis and intersects the sets of likes belonging to self
      # and rater.
      #
      # @param [Object] rater the person whose set of likes you wish to intersect with that of self
      # @param [Hash] options the options for this intersection
      # @option options [Class, String, Symbol] :class ('nil') Restrict the intersection to a single recommendable type. By default, all recomendable types are considered
      # @option options [true, false] :return_records (true) Return the actual Model instances
      # @return [Array] Typically, an array of ActiveRecord objects (unless :return_records is false)
      def common_likes_with(rater, options = {})
        defaults = { :class => nil,
                     :return_records => true }
        options = defaults.merge(options)
        create_recommended_to_sets and rater.create_recommended_to_sets if options[:return_records]

        if options[:class]
          in_common = Recommendable.redis.sinter likes_set_for(options[:class]), rater.likes_set_for(options[:class])
          in_common = options[:class].to_s.classify.constantize.find in_common if options[:return_records]
        else
          in_common = Recommendable.recommendable_classes.flat_map do |klass|
            things = Recommendable.redis.sinter(likes_set_for(klass), rater.likes_set_for(klass))

            if options[:return_records]
              klass.to_s.classify.constantize.find(things)
            else
              things.map {|id| "#{klass.to_s.classify}:#{id}"}
            end
          end
        end

        destroy_recommended_to_sets and rater.destroy_recommended_to_sets if options[:return_records]
        in_common
      end
      
      # Makes a call to Redis and intersects the sets of dislikes belonging to
      # self and rater.
      #
      # @param [Object] rater the person whose set of dislikes you wish to intersect with that of self
      # @param [Hash] options the options for this intersection
      # @option options [Class, String, Symbol] :class ('nil') Restrict the intersection to a single recommendable type. By default, all recomendable types are considered
      # @option options [true, false] :return_records (true) Return the actual Model instances
      # @return [Array] Typically, an array of ActiveRecord objects (unless :return_records is false)
      def common_dislikes_with(rater, options = {})
        defaults = { :class => nil,
                     :return_records => true }
        options = defaults.merge(options)
        create_recommended_to_sets and rater.create_recommended_to_sets if options[:return_records]

        if options[:class]
          in_common = Recommendable.redis.sinter dislikes_set_for(options[:class]), rater.dislikes_set_for(options[:class])
          in_common = options[:class].to_s.classify.constantize.find in_common if options[:return_records]
        else
          in_common = Recommendable.recommendable_classes.flat_map do |klass|
            things = Recommendable.redis.sinter(dislikes_set_for(klass), rater.dislikes_set_for(klass))

            if options[:return_records]
              klass.to_s.classify.constantize.find(things)
            else
              things.map {|id| "#{klass.to_s.classify}:#{id}"}
            end
          end
        end

        destroy_recommended_to_sets and rater.destroy_recommended_to_sets if options[:return_records]
        in_common
      end
      
      # Makes a call to Redis and intersects self's set of likes with rater's
      # set of dislikes and vise versa. The idea here is that if self likes
      # an object that rater dislikes, it is a disagreement and should count
      # negatively towards their similarity.
      #
      # @param [Object] rater the person whose sets you wish to intersect with those of self
      # @param [Hash] options the options for this intersection
      # @option options [Class, String, Symbol] :class ('nil') Restrict the intersections to a single recommendable type. By default, all recomendable types are considered
      # @option options [true, false] :return_records (true) Return the actual Model instances
      # @return [Array] Typically, an array of ActiveRecord objects (unless :return_records is false)
      def disagreements_with(rater, options = {})
        defaults = { :class => nil,
                     :return_records => true }
        options = defaults.merge(options)
        create_recommended_to_sets and rater.create_recommended_to_sets if options[:return_records]
        
        if options[:class]
          disagreements =  Recommendable.redis.sinter(likes_set_for(options[:class]), rater.dislikes_set_for(options[:class]))
          disagreements += Recommendable.redis.sinter(dislikes_set_for(options[:class]), rater.likes_set_for(options[:class]))
          disagreements = options[:class].to_s.classify.constantize.find disagreements if options[:return_records]
        else
          disagreements = Recommendable.recommendable_classes.flat_map do |klass|
            things = Recommendable.redis.sinter(likes_set_for(klass), rater.dislikes_set_for(klass))
            things += Recommendable.redis.sinter(dislikes_set_for(klass), rater.likes_set_for(klass))
            
            if options[:return_records]
              klass.to_s.classify.constantize.find(things)
            else
              things.map {|id| "#{options[:class].to_s.classify}:#{id}"}
            end
          end
        end

        destroy_recommended_to_sets and rater.destroy_recommended_to_sets if options[:return_records]
        disagreements
      end

      # Used internally during liking/disliking/stashing/ignoring objects. This
      # will prep an object to be liked, disliked, etc. by making sure that self
      # doesn't already have this item in their list of likes, dislikes, stashed
      # items or ignored items.
      #
      # param [Object] object the object to destroy Recommendable models for
      # @private
      def completely_unrecommend(object)
        unlike(object)
        undislike(object)
        unstash(object)
        unignore(object)
        unpredict(object)
      end

      protected

      # @private
      def likes_set_for(klass)
        "#{self.class}:#{id}:likes:#{klass}"
      end
      
      # @private
      def dislikes_set_for(klass)
        "#{self.class}:#{id}:dislikes:#{klass}"
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

      private

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
        rater.create_recommended_to_sets
        agreements = common_likes_with(rater, :return_records => false).size
        agreements += common_dislikes_with(rater, :return_records => false).size
        disagreements = disagreements_with(rater, :return_records => false).size
        
        similarity = (agreements - disagreements).to_f / (likes.count + dislikes.count)
        rater.destroy_recommended_to_sets
        
        return similarity
      end

      # Used internally to update self's prediction values across all
      # recommendable types. This is called in the Resque job to refresh
      # recommendations.
      #
      # @private
      def update_recommendations
        Recommendable.recommendable_classes.each {|klass| update_recommendations_for klass}
      end
      
      # Used internally to update self's prediction values across a single
      # recommendable type. Convenience method for {#update_recommendations}
      #
      # @param [Class] klass the recommendable type to update predictions for
      # @private
      def update_recommendations_for(klass)
        klass.find_each do |object|
          next if rated?(object) || !object.been_rated? || ignored?(object) || stashed?(object)
          prediction = predict(object)
          Recommendable.redis.zadd(predictions_set_for(object.class), prediction, object.redis_key) if prediction
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
        liked_by, disliked_by = object.send :create_recommendable_sets
        rated_by = Recommendable.redis.scard(liked_by) + Recommendable.redis.scard(disliked_by)
        similarity_sum = 0.0
        prediction = 0.0
      
        Recommendable.redis.smembers(liked_by).inject(similarity_sum) {|sum, r| sum += Recommendable.redis.zscore(similarity_set, r).to_f }
        Recommendable.redis.smembers(disliked_by).inject(similarity_sum) {|sum, r| sum -= Recommendable.redis.zscore(similarity_set, r).to_f }
      
        prediction = similarity_sum / rated_by.to_f
        
        object.send :destroy_recommendable_sets
        
        return prediction
      end
      
      # Used internally to update the similarity values between self and all
      # other users. This is called in the Resque job to refresh recommendations.
      #
      # @private
      def update_similarities
        return unless rated_anything?
        create_recommended_to_sets
        
        Recommendable.user_class.find_each do |rater|
          next if self == rater || !rater.rated_anything?
          Recommendable.redis.zadd similarity_set, similarity_with(rater), rater.id
        end
        
        destroy_recommended_to_sets
      end
      
      # @private
      def unpredict(object)
        Recommendable.redis.zrem predictions_set_for(object.class), object.redis_key
      end

      # @private
      def similarity_set
        "#{self.class}:#{id}:similarities"
      end
      
      # @private
      def predictions_set_for(klass)
        "#{self.class}:#{id}:predictions:#{klass}"
      end
    end
  end
end
