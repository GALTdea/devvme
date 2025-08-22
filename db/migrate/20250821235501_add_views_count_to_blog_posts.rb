class AddViewsCountToBlogPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :blog_posts, :views_count, :integer, default: 0, null: false
    add_index :blog_posts, :views_count
  end
end
