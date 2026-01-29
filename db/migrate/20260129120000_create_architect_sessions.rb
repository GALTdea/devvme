# frozen_string_literal: true

class CreateArchitectSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :architect_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: 'draft'
      t.string :goal, null: false
      t.jsonb :context_snapshot, default: {}
      t.text :generated_bio
      t.text :generated_headline
      t.integer :question_count, null: false, default: 0

      t.timestamps
    end

    add_index :architect_sessions, [:user_id, :created_at], if_not_exists: true
    add_index :architect_sessions, :status, if_not_exists: true
  end
end
