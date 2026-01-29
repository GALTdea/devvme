# frozen_string_literal: true

class CreateArchitectMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :architect_messages do |t|
      t.references :architect_session, null: false, foreign_key: true
      t.string :role, null: false
      t.text :content, null: false
      t.integer :sequence, null: false
      t.string :topic
      t.string :insight_type
      t.jsonb :metadata, default: {}, null: false

      t.timestamps
    end

    add_index :architect_messages, [:architect_session_id, :sequence], unique: true, if_not_exists: true
    add_index :architect_messages, :architect_session_id, if_not_exists: true
  end
end
