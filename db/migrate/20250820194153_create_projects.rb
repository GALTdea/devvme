class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.string :title
      t.text :description
      t.text :technologies
      t.string :github_url
      t.string :demo_url
      t.references :user, null: false, foreign_key: true
      t.integer :status
      t.boolean :featured

      t.timestamps
    end
  end
end
