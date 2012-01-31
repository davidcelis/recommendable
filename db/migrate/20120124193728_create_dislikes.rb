class CreateDislikes < ActiveRecord::Migration
  def up
    create_table :dislikes do |t|
      t.references :user
      t.references :dislikeable, :polymorphic => true
      t.timestamps
    end
    
    add_index :dislikes, :dislikeable_id
    add_index :dislikes, :dislikeable_type
    add_index :dislikes, [:user_id, :dislikeable_id, :dislikeable_type], :unique => true, :name => "user_dislike_constraint"
  end

  def down
    drop_table :dislikes
  end
end
