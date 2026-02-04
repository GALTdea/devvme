class AddMultiModeFieldsToArchitectSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :architect_sessions, :mode, :string, null: false, default: "profile_builder"
    add_column :architect_sessions, :target_type, :string
    add_column :architect_sessions, :target_data, :jsonb, null: false, default: {}
    add_column :architect_sessions, :result_data, :jsonb, null: false, default: {}
    add_column :architect_sessions, :context_version, :integer, null: false, default: 1

    add_index :architect_sessions, :mode
    add_index :architect_sessions, :target_type
  end
end
