class AddTitleAndCompanyToContacts < ActiveRecord::Migration
  def change
    add_column :contacts, :title, :string
    add_column :contacts, :company, :string
    add_column :contacts, :email, :string
  end
end
