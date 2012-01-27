module Recommendable
  class Railtie < Rails::Railtie
    ActiveRecord::Base.send(:include, Recommendable::ActsAsRecommendedTo)
    ActiveRecord::Base.send(:include, Recommendable::ActsAsRecommendable)
  end
end
