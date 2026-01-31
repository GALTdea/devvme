class AddAllowCareerArchitectToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :allow_career_architect, :boolean, default: false, null: false
    add_index :users, :allow_career_architect, where: "allow_career_architect = true"
  end
end
