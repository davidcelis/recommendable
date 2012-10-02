class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :username
      t.integer :likes_count,    :default => 0
      t.integer :dislikes_count, :default => 0

      t.timestamps
    end
  end
end
