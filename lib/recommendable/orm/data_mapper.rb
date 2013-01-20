require 'dm-core'

DataMapper::Model.append_extensions(Recommendable::Rater::ClassMethods)
DataMapper::Model.append_extensions(Recommendable::Ratable::ClassMethods)

module Recommendable::Ratable::InstanceMethods
  def recommendable?() self.class.recommendable? end
end

DataMapper::Model.append_inclusions(Recommendable::Ratable::InstanceMethods)

Recommendable.configure { |config| config.orm = :data_mapper }
