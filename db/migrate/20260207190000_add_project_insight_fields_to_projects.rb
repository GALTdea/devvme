class AddProjectInsightFieldsToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :project_insight_enabled, :boolean, default: false, null: false
    add_column :projects, :project_insight_last_analyzed_at, :datetime
    add_column :projects, :project_insight_analysis, :jsonb, default: {}, null: false

    add_index :projects, :project_insight_enabled
  end
end
