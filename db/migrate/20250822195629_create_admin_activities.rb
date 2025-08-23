class CreateAdminActivities < ActiveRecord::Migration[8.0]
  def change
    create_table :admin_activities do |t|
      t.references :admin, null: false, foreign_key: { to_table: :users }
      t.string :action, null: false
      t.string :target_type
      t.bigint :target_id
      t.json :details, default: {}
      t.string :ip_address
      t.string :user_agent, limit: 500

      t.timestamps
    end

    add_index :admin_activities, [:target_type, :target_id]
    add_index :admin_activities, :action
    add_index :admin_activities, :created_at
    add_index :admin_activities, [:admin_id, :created_at]
  end
end
