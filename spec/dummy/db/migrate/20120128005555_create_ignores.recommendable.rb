# This migration comes from recommendable (originally 20120127092558)
class CreateIgnores < ActiveRecord::Migration
  def up
    create_table :recommendable_ignores, :force => true do |t|
      t.references :user
      t.references :ignorable, :polymorphic => true
      t.timestamps
    end
    
    add_index :recommendable_ignores, :ignorable_id
    add_index :recommendable_ignores, :ignorable_type
    add_index :recommendable_ignores, [:user_id, :ignorable_id, :ignorable_type], :unique => true, :name => "user_ignore_constraint"
  end
  
  def down
    drop_table :recommendable_ignores
  end
end
