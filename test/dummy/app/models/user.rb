class User < ActiveRecord::Base
  attr_accessible :email if ::ActiveRecord::VERSION::MAJOR < 4
  recommends :movies, :books, :cars
end
