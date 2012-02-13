class CreateDislikes < ActiveRecord::Migration
  def up
    create_table :recommendable_dislikes do |t|
      t.references :user
      t.references :dislikeable, :polymorphic => true
      t.timestamps
    end
    
    add_index :recommendable_dislikes, :dislikeable_id
    add_index :recommendable_dislikes, :dislikeable_type
    add_index :recommendable_dislikes, [:user_id, :dislikeable_id, :dislikeable_type], :unique => true, :name => "user_dislike_constraint"
  end

  def down
    drop_table :recommendable_dislikes
  end
end
