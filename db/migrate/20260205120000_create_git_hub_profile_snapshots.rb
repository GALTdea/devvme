# frozen_string_literal: true

class CreateGitHubProfileSnapshots < ActiveRecord::Migration[7.1]
  def change
    create_table :github_profile_snapshots do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :username, null: false
      t.jsonb :payload, null: false, default: {}
      t.datetime :fetched_at
      t.timestamps
    end

    add_index :github_profile_snapshots, :username
  end
end
