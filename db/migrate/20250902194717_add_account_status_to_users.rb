class AddAccountStatusToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :account_status, :integer, default: 0, null: false
    add_index :users, :account_status
  end
end
