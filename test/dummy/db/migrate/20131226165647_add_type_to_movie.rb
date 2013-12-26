class AddTypeToMovie < ActiveRecord::Migration
  def change
    add_column :movies, :type, :string
  end
end
