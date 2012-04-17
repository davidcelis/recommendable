class CreateStashes < ActiveRecord::Migration
  def up
    create_table :recommendable_stashes do |t|
      t.references :user
      t.references :stashable, :polymorphic => true
      t.timestamps
    end
    
    add_index :recommendable_stashes, :stashable_id
    add_index :recommendable_stashes, :stashable_type
    add_index :recommendable_stashes, [:user_id, :stashable_id, :stashable_type], :unique => true, :name => "user_stashed_constraint"
  end
  
  def down
    drop_table :recommendable_stashes
  end
end
