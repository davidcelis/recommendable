class CreateStashedItems < ActiveRecord::Migration
  def up
    create_table :recommendable_stashed_items do |t|
      t.references :user
      t.references :stashable, :polymorphic => true
      t.timestamps
    end
    
    add_index :recommendable_stashed_items, :stashable_id
    add_index :recommendable_stashed_items, :stashable_type
    add_index :recommendable_stashed_items, [:user_id, :stashable_id, :stashable_type], :unique => true, :name => "user_stashed_constraint"
  end
  
  def down
    drop_table :recommendable_stashed_items
  end
end
