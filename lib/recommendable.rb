require 'recommendable/engine'
require 'recommendable/acts_as_recommended_to'
require 'recommendable/acts_as_recommendable'
require 'recommendable/railtie' if defined?(Rails)

module Recommendable
  mattr_accessor :redis, :user_class
  mattr_writer :user_class, :recommendable_classes
  
  def self.user_class
    @@user_class.camelize.constantize
  end
  
  def self.recommendable_classes
    @@recommendable_classes ||= []
  end
end