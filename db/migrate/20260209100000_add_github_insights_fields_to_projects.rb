class AddGitHubInsightsFieldsToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :github_insights_enabled, :boolean, default: true, null: false
    add_column :projects, :github_insights_sync_status, :string, default: "never", null: false
    add_column :projects, :github_insights_last_synced_at, :datetime
    add_column :projects, :github_insights_last_error, :text
    add_column :projects, :github_insights_summary, :jsonb, default: {}, null: false

    add_index :projects, :github_insights_enabled
    add_index :projects, :github_insights_sync_status
  end
end
