module Recommendable
  module Helpers
    def manual_join(klass, action)
      table = klass.base_class.table_name
      "JOIN #{table} ON recommendable_#{action.pluralize}.#{action}able_id = #{table}.id AND #{table}.type = '#{klass}'"
    end
  end
end
