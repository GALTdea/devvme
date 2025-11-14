class CreateWaitingListEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :waiting_list_entries do |t|
      t.string :email, null: false
      t.string :full_name
      t.integer :status, default: 0, null: false
      t.integer :position
      t.string :source
      t.jsonb :metadata, default: {}, null: false
      t.bigint :user_id
      t.datetime :notified_at
      t.datetime :converted_at

      t.timestamps
    end

    add_index :waiting_list_entries, :email
    add_index :waiting_list_entries, :status
    add_index :waiting_list_entries, :position
    add_index :waiting_list_entries, :user_id
    add_index :waiting_list_entries, :created_at
    add_foreign_key :waiting_list_entries, :users, column: :user_id
  end
end
