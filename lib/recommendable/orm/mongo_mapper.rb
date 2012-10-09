require 'mongo_mapper'

MongoMapper::Document.plugin(Recommendable::Rater)
MongoMapper::Document.plugin(Recommendable::Ratable)
MongoMapper::EmbeddedDocument.plugin(Recommendable::Rater)
MongoMapper::EmbeddedDocument.plugin(Recommendable::Ratable)

Recommendable.configure { |config| config.orm = :mongo_mapper }
