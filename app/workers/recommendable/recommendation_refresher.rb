module Recommendable
  class RecommendationRefresher
    include Resque::Plugins::UniqueJob
    @queue = :recommendable
    
    def self.perform(user_id, other_ids)
      user = Recommendable.user_class.find(user_id)
      return if other_ids.empty?
      user.send :update_similarities, other_ids
      user.send :update_recommendations
    end
  end
end
