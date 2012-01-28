class User < ActiveRecord::Base
  acts_as_recommended_to
end
