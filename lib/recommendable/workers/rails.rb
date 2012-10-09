module Recommendable
  module Workers
    if defined?(Rails::Queueing)
      class Rails
        attr_accessor :user_id

        def initialize(user_id)
          @user_id = user_id
        end

        def run
          Recommendable::Helpers::Calculations.update_similarities_for(user_id)
          Recommendable::Helpers::Calculations.update_recommendations_for(user_id)
        end
      end
    end
  end
end
