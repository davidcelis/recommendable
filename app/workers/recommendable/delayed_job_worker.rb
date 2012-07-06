module Recommendable
  if defined?(Delayed::Job)
    class DelayedJobWorker
      attr_accessor :user_id
  
      def initialize(user_id)
        @user_id = user_id
      end
      
      def perform
        user = Recommendable.user_class.find(self.user_id)
        user.send :update_similarities
        user.send :update_recommendations
      end
    end
  end
end
