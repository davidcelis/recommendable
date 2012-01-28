class CreateBullies < ActiveRecord::Migration
  def change
    create_table :bullies do |t|
      t.string :username

      t.timestamps
    end
  end
end
