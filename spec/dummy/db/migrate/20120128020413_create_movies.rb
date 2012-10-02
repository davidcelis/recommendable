class CreateMovies < ActiveRecord::Migration
  def change
    create_table :movies do |t|
      t.string :title
      t.integer :year
      t.integer :likes_count,    :default => 0
      t.integer :dislikes_count, :default => 0

      t.timestamps
    end
  end
end
