module Recommendable
  if defined?(Resque)
    class ResqueWorker
      include Resque::Plugins::UniqueJob if defined?(Resque::Plugins::UniqueJob)
      @queue = :recommendable
      
      def self.perform(user_id)
        user = Recommendable.user_class.find(user_id)
        user.send :update_similarities
        user.send :update_recommendations
      end
    end
  end
end
