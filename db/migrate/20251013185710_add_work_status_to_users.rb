class AddWorkStatusToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :open_for_work, :boolean, default: false, null: false
    add_column :users, :work_preferences, :jsonb, default: {}, null: false
  end
end
