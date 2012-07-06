module Recommendable
  if defined?(Rails::Queueing)
    class RailsWorker
      attr_accessor :user_id
  
      def initialize(user_id)
        @user_id = user_id
      end
      
      def run
        user = Recommendable.user_class.find(self.user_id)
        user.send :update_similarities
        user.send :update_recommendations
      end
    end
  end
end
