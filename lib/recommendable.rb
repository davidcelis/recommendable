require 'recommendable/engine'
require 'recommendable/acts_as_rater'
require 'recommendable/acts_as_rateable'
require 'recommendable/railtie' if defined?(Rails)

module Recommendable
  mattr_accessor :redis
  mattr_writer :user_class
  
  def self.user_class
    @@user_class.camelize.constantize
  end
end