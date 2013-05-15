$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'recommendable/version'

Gem::Specification.new do |s|
  s.name        = 'recommendable'
  s.version     = Recommendable::VERSION
  s.summary     = 'A Like/Dislike recommendation engine for Ruby apps using Redis'
  s.description = <<EOF
A Like/Dislike recommendation engine for Ruby apps using Redis.
EOF

  s.files       = Dir['lib/**/*']
  s.test_files  = Dir['test/**/*']

  s.has_rdoc    = 'yard'

  s.authors     = ['David Celis']
  s.email       = %w[david@davidcelis.com]
  s.homepage    = 'https://github.com/davidcelis/recommendable'

  s.add_dependency 'activesupport', '>= 3.0.0'
  s.add_dependency 'redis',         '>= 2.2.0'
  s.add_dependency 'hooks',         '>= 0.2.1'

  s.add_development_dependency 'minitest'
  s.add_development_dependency 'miniskirt'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'rails', '>= 3.1.0'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'database_cleaner'
end
