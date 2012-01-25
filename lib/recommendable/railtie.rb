module Recommendable
  class Railtie < Rails::Railtie
    ActiveRecord::Base.send(:include, Recommendable::ActsAsRater)
    ActiveRecord::Base.send(:include, Recommendable::ActsAsRateable)
  end
end