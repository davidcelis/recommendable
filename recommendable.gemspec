#  encoding: utf-8
require File.expand_path('../lib/recommendable/version')

Gem::Specification.new do |s|
  s.name = "recommendable"
  s.version = Recommendable::VERSION
  s.date = "2012-01-28"
  
  s.authors = ["David Celis"]
  s.email = "david@davidcelis.com"
  s.homepage = "http://github.com/davidcelis/recommendable"
  
  s.summary = "Add like-based and/or dislike-based recommendations to your app."
  s.description = "Allow a model (typically User) to Like and/or Dislike models in your app. Generate recommendations quickly using redis."
  
  s.files = `git ls-files`.split("\n")
  
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "minitest"
  s.add_development_dependency "shoulda"
  s.add_development_dependency "yard", "~> 0.6.0"
  s.add_development_dependency "bundler", "~> 1.0.0"
  s.add_development_dependency "jeweler", "~> 1.6.4"
  s.add_development_dependency "rcov"
  
  s.add_dependency "rails", ">= 3.1.0"
  s.add_dependency "redis", "~> 2.2.0"
  s.add_dependency "resque", "~> 1.19.0"
  s.add_dependency "resque-loner", "~> 1.2.0"
end

