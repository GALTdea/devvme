class AddProjectStoryToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :project_story, :jsonb, default: {}, null: false
  end
end
