# This migration comes from recommendable (originally 20120127092558)
class CreateIgnores < ActiveRecord::Migration
  def up
    create_table :ignores, :force => true do |t|
      t.references :user
      t.references :ignoreable, :polymorphic => true
      t.timestamps
    end
    
    add_index :ignores, :ignoreable_id
    add_index :ignores, :ignoreable_type
    add_index :ignores, [:user_id, :ignoreable_id, :ignoreable_type], :unique => true, :name => "user_ignore_constraint"
  end
  
  def down
    drop_table :ignores
  end
end
