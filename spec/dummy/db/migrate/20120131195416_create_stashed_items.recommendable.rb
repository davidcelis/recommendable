# This migration comes from recommendable (originally 20120131173909)
class CreateStashedItems < ActiveRecord::Migration
  def up
    create_table :stashed_items do |t|
      t.references :user
      t.references :stashable, :polymorphic => true
      t.timestamps
    end
    
    add_index :stashed_items, :stashable_id
    add_index :stashed_items, :stashable_type
    add_index :stashed_items, [:user_id, :stashable_id, :stashable_type], :unique => true, :name => "user_stashed_constraint"
  end
  
  def down
    drop_table :stashed_items
  end
end
