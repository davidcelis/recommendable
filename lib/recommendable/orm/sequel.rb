require 'sequel'


Sequel::Model.send(:include, Recommendable::Rater)
Sequel::Model.send(:include, Recommendable::Ratable)

Recommendable.configure { |config| config.orm = :sequel }
