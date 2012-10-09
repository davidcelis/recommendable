module Recommendable
  module Helpers
    module Queriers
      class << self
        def active_record(klass, ids)
          klass.where(:id => ids)
        end

        def data_mapper(klass, ids)
          klass.all(:id => ids)
        end

        def mongoid(klass, ids)
          klass.where(:id => ids)
        end

        def mongo_mapper(klass, ids)
          klass.where(:id => ids)
        end
      end
    end
  end
end
