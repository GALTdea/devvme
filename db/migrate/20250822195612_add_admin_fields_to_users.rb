class AddAdminFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :role, :integer, default: 0, null: false
    add_column :users, :suspended_at, :datetime
    add_column :users, :suspension_reason, :text
    add_column :users, :last_login_at, :datetime
    add_column :users, :admin_notes, :text

    add_index :users, :role
    add_index :users, :suspended_at
    add_index :users, :last_login_at
  end
end
