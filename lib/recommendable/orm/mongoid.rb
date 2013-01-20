require 'mongoid'

Mongoid::Document::ClassMethods.send(:include, Recommendable::Rater::ClassMethods)
Mongoid::Document::ClassMethods.send(:include, Recommendable::Ratable::ClassMethods)

module Recommendable::Ratable::InstanceMethods
  def recommendable?() self.class.recommendable? end
end

Mongoid::Document.send(:include, Recommendable::Ratable::InstanceMethods)

Recommendable.configure { |config| config.orm = :mongoid }
