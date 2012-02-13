# This migration comes from recommendable (originally 20120124193723)
class CreateLikes < ActiveRecord::Migration
  def up
    create_table :recommendable_likes, :force => true do |t|
      t.references :user
      t.references :likeable, :polymorphic => true
      t.timestamps
    end
    
    add_index :recommendable_likes, :likeable_id
    add_index :recommendable_likes, :likeable_type
    add_index :recommendable_likes, [:user_id, :likeable_id, :likeable_type], :unique => true, :name => "user_like_constraint"
  end

  def down
    drop_table :recommendable_likes
  end
end
