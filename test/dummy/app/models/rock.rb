class Rock < ActiveRecord::Base
  attr_accessible :name if ::ActiveRecord::VERSION::MAJOR < 4
end
