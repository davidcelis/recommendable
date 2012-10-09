class CreateRocks < ActiveRecord::Migration
  def change
    create_table :rocks do |t|
      t.string :name

      t.timestamps
    end
  end
end
