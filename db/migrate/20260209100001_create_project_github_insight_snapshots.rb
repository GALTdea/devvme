class CreateProjectGitHubInsightSnapshots < ActiveRecord::Migration[8.0]
  def change
    create_table :project_github_insight_snapshots do |t|
      t.references :project, null: false, foreign_key: true
      t.string :sync_type, null: false
      t.string :source, null: false
      t.datetime :captured_at, null: false
      t.jsonb :repo_payload, null: false, default: {}
      t.jsonb :metrics_payload, null: false, default: {}
      t.jsonb :highlights_payload, null: false, default: {}
      t.jsonb :errors_payload, null: false, default: {}
      t.integer :duration_ms
      t.timestamps
    end

    add_index :project_github_insight_snapshots, [:project_id, :captured_at], name: "idx_proj_gh_insight_snapshots_project_captured"
    add_index :project_github_insight_snapshots, :sync_type
    add_index :project_github_insight_snapshots, :source
  end
end
