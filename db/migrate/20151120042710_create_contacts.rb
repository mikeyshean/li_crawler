class CreateContacts < ActiveRecord::Migration
  def change
    create_table :contacts do |t|
      t.string :name, null: false
      t.integer :linkedin_id, null: false
      t.string :profile_link, null: false
      t.timestamps null: false
    end
    add_index :contacts, :linkedin_id, unique: true
  end
end
