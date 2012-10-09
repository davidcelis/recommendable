require 'mongoid'

Mongoid::Document::ClassMethods.send(:include, Recommendable::Rater::ClassMethods)
Mongoid::Document::ClassMethods.send(:include, Recommendable::Ratable::ClassMethods)
Mongoid::Document.send(:include, Recommendable::Ratable::InstanceMethods)

Recommendable.configure { |config| config.orm = :mongoid }
