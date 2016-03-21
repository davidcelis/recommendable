module Recommendable
  module Workers
    class Sidekiq
      if defined?(::Sidekiq)
        include ::Sidekiq::Worker
      end

      def perform(user_id)
        lock.lock
        queue = ::Sidekiq::Queue.new
        # skip if there are same job in the queue
        queue.select {|job| job.klass == self.class.to_s }.each do |job|
          if job.args[0] == user_id
            lock.unlock
            return
          end
        end
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
