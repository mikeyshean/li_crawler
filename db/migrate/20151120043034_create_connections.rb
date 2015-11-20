class CreateConnections < ActiveRecord::Migration
  def change
    create_table :connections do |t|
      t.integer :user_id
      t.integer :contact_id
      t.integer :degree
    end

    add_index :connections, :user_id
    add_index :connections, :contact_id
  end
end
