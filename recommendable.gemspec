#  encoding: utf-8
require File.expand_path('lib/recommendable/version')

Gem::Specification.new do |s|
  s.name = 'recommendable'
  s.version = Recommendable::VERSION
  s.date = Time.now.strftime('%Y-%m-%d')
  
  s.authors = ['David Celis']
  s.email = 'david@davidcelis.com'
  s.homepage = 'http://github.com/davidcelis/recommendable'
  
  s.summary = 'Add like-based and/or dislike-based recommendations to your app.'
  s.description = 'Allow a model (typically User) to Like and/or Dislike models in your app. Generate recommendations quickly using redis.'
  
  s.files = `git ls-files`.split("\n")
  s.has_rdoc = 'yard'
  
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'miniskirt'
  s.add_development_dependency 'shoulda'
  s.add_development_dependency 'yard', '~> 0.6.0'
  s.add_development_dependency 'bundler'
  
  s.add_dependency 'rails', '>= 3.0.0'
  s.add_dependency 'redis', '>= 2.2.0'
  s.add_dependency 'hooks', '>= 0.2.1'
end

