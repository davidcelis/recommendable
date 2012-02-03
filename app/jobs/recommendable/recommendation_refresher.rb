module Recommendable
  class RecommendationRefresher
    include Resque::Plugins::UniqueJob
    @queue = :recommendable
    
    def self.perform(user_id)
      user = Recommendable.user_class.find(user_id)
      user.send :update_similarities
      user.send :update_recommendations
    end
  end
end
