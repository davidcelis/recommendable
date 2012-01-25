require "recommendable/engine"
require "recommendable/rater"

module Recommendable
  mattr_accessor :user_class, :redis
  
  def self.user_class
    @@user_class.to_s.camelize.constantize
  end
end