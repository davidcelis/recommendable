module Recommendable
  module Workers
    class Sidekiq
      if defined?(::Sidekiq)
        include ::Sidekiq::Worker
        sidekiq_options :unique => true, :queue => :recommendable
      end

      def perform(user_id)
        return if $current_job == user_id
        lock.lock
        $current_job = user_id
        Recommendable::Helpers::Calculations.update_similarities_for(user_id)
        Recommendable::Helpers::Calculations.update_recommendations_for(user_id)
        $current_job = nil
        lock.unlock
      end

      private
      def lock
        $_lock ||= Mutex.new
      end
    end
  end
end
