module Recommendable
  class RecommendationRefresher
    include Resque::Plugins::UniqueJob
    @queue = :recommendable
    
    def self.perform(user_id)
      user = Recommendable.user_class.find(user_id)
      user.update_similarities
      user.update_recommendations
    end
  end
end