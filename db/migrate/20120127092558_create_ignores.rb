class CreateIgnores < ActiveRecord::Migration
  def up
    create_table :recommendable_ignores do |t|
      t.references :user
      t.references :ignoreable, :polymorphic => true
      t.timestamps
    end
    
    add_index :recommendable_ignores, :ignoreable_id
    add_index :recommendable_ignores, :ignoreable_type
    add_index :recommendable_ignores, [:user_id, :ignoreable_id, :ignoreable_type], :unique => true, :name => "user_ignore_constraint"
  end
  
  def down
    drop_table :recommendable_ignores
  end
end
