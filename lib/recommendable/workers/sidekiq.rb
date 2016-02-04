module Recommendable
  module Workers
    class Sidekiq
      if defined?(::Sidekiq)
        include ::Sidekiq::Worker
      end

      def perform(user_id)
        lock.lock
        Recommendable::Helpers::Calculations.update_similarities_for(user_id)
        Recommendable::Helpers::Calculations.update_recommendations_for(user_id)
        lock.unlock
      end

      private
      def lock
        $_lock ||= Mutex.new
      end
    end
  end
end
