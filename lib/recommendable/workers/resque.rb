module Recommendable
  module Workers
    class Resque
      include ::Resque::Plugins::UniqueJob if defined?(::Resque::Plugins::UniqueJob)
      @queue = :recommendable

      def self.perform(user_id)
        Recommendable::Helpers::Calculations.update_similarities_for(user_id)
        Recommendable::Helpers::Calculations.update_recommendations_for(user_id)
      end
    end
  end
end
