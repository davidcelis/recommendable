class Movie < ActiveRecord::Base
  attr_accessible :title, :year if ::ActiveRecord::VERSION::MAJOR < 4
end
