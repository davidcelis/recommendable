require 'dm-core'

DataMapper::Model.append_extensions(Recommendable::Rater::ClassMethods)
DataMapper::Model.append_extensions(Recommendable::Ratable::ClassMethods)
DataMapper::Model.append_inclusions(Recommendable::Ratable::InstanceMethods)

Recommendable.configure { |config| config.orm = :data_mapper }
