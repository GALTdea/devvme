class AddArchivedToBlogPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :blog_posts, :archived, :boolean, default: false, null: false
    add_index :blog_posts, :archived
  end
end
