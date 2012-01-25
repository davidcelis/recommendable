require 'recommendable/engine'
require 'recommendable/acts_as_rater'
require 'recommendable/acts_as_rateable'
require 'recommendable/railtie' if defined?(Rails)

module Recommendable
  mattr_writer :user_class, :redis
  
  def self.user_class
    @@user_class.camelize.constantize
  end
end