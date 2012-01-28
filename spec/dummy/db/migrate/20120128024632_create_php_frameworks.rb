class CreatePhpFrameworks < ActiveRecord::Migration
  def change
    create_table :php_frameworks do |t|
      t.string :name

      t.timestamps
    end
  end
end
