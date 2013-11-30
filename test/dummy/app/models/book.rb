class Book < ActiveRecord::Base
  attr_accessible :author, :title if ::ActiveRecord::VERSION::MAJOR < 4
end
