class User < ActiveRecord::Base
  attr_accessible :email
  recommends :movies, :books
end
