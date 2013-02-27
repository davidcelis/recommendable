module Recommendable
  module Workers
    class TorqueBox
      if defined?(::TorqueBox::Messaging::Backgroundable)
        include ::TorqueBox::Messaging::Backgroundable
        always_background :enqueue
      end

      def self.enqueue(user_id)
        Recommendable::Helpers::Calculations.update_similarities_for(user_id)
        Recommendable::Helpers::Calculations.update_recommendations_for(user_id)
      end
    end
  end
end
