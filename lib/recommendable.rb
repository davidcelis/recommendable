require 'recommendable/engine'
require 'recommendable/helpers'
require 'recommendable/acts_as_recommended_to'
require 'recommendable/acts_as_recommendable'
require 'recommendable/exceptions'
require 'recommendable/railtie' if defined?(Rails)
require 'recommendable/version'

module Recommendable
  mattr_accessor :redis, :user_class
  mattr_writer :recommendable_classes
  
  def self.recommendable_classes
    @@recommendable_classes ||= []
  end

  def self.enqueue(user_id)
    Resque.enqueue RecommendationRefresher, user_id
  end
end
