module Recommendable
  module Workers
    if defined?(Delayed::Job)
      class DelayedJob
        attr_accessor :user_id

        def initialize(user_id)
          @user_id = user_id
        end

        def perform
          Recommendable::Helpers::Calculations.update_similarities_for(user_id)
          Recommendable::Helpers::Calculations.update_recommendations_for(user_id)
        end
      end
    end
  end
end
