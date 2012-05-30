module Recommendable
  module Helpers
    def manual_join(klass, action)
      table = klass.base_class.table_name
      inheritance_column = klass.base_class.inheritance_column
      "JOIN #{table} ON recommendable_#{action.pluralize}.#{action}able_id = #{table}.id AND #{table}.#{inheritance_column} = '#{klass}'"
    end
  end
end
