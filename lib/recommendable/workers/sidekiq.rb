module Recommendable
  module Workers
    if defined?(Sidekiq)
      class Sidekiq
        include ::Sidekiq::Worker
        sidekiq_options :unique => true, :queue => :recommendable

        def perform(user_id)
          Recommendable::Helpers::Calculations.update_similarities_for(user_id)
          Recommendable::Helpers::Calculations.update_recommendations_for(user_id)
        end
      end
    end
  end
end
