module Recommendable
  module Helpers
    module RedisKeyMapper
      class << self
        %w[scored bookmarked recommended].each do |action|
          define_method "#{action}_set_for" do |klass, id|
            [redis_namespace, user_namespace, id, "#{action}_#{ratable_namespace(klass)}"].compact.join(':')
          end
        end

        def similarity_set_for(id)
          [redis_namespace, user_namespace, id, 'similarities'].compact.join(':')
        end

        def scored_by_set_for(klass, id)
          [redis_namespace, ratable_namespace(klass), id, 'scored_by'].compact.join(':')
        end

        def bookmarked_by_set_for(klass, id)
          [redis_namespace, ratable_namespace(klass), id, 'bookmarked_by'].compact.join(':')
        end

        def score_set_for(klass)
          [redis_namespace, ratable_namespace(klass), 'scores'].join(':')
        end

        def temp_set_for(klass, id)
          [redis_namespace, ratable_namespace(klass), id, 'temp'].compact.join(':')
        end

        private

        def redis_namespace
          Recommendable.config.redis_namespace
        end

        def user_namespace
          Recommendable.config.user_class.to_s.tableize
        end

        # If the class or a superclass has been configured as ratable with <tt>recommends :class_name</tt>
        # then that ratable class is used to produce the namespace. Fall back on just using the given class.
        def ratable_namespace(klass)
          klass = klass.ratable_class if klass.respond_to?(:ratable_class)
          klass.to_s.tableize
        end
      end
    end
  end
end
