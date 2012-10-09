require 'active_record'

ActiveRecord::Base.send(:include, Recommendable::Rater)
ActiveRecord::Base.send(:include, Recommendable::Ratable)

Recommendable.configure { |config| config.orm = :active_record }
