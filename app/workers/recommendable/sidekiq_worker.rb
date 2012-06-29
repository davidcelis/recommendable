module Recommendable
  class SidekiqWorker
    include Sidekiq::Worker
    @sidekiq_options :queue => :recommendable
    
    def perform(user_id)
      user = Recommendable.user_class.find(user_id)
      user.send :update_similarities
      user.send :update_recommendations
    end
  end
end
