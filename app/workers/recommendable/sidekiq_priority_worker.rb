module Recommendable
  if defined?(Sidekiq)
    class SidekiqPriorityWorker
      include ::Sidekiq::Worker
      sidekiq_options :unique => true, :queue => :recommendable_priority

      def perform(user_id)
        user = Recommendable.user_class.find(user_id)
        user.send :update_similarities, :priority => true
        user.send :update_recommendations, :priority => true
      end
    end
  end
end
