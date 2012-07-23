module Recommendable
  if defined?(Sidekiq)
    class SidekiqWorker
      include ::Sidekiq::Worker
      sidekiq_options :queue => :recommendable, :unique => true
      
      def perform(user_id)
        user = Recommendable.user_class.find(user_id)
        user.send :update_similarities
        user.send :update_recommendations
      end
    end
  end
end
