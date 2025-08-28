class AddFeaturedToBlogPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :blog_posts, :featured, :boolean
  end
end
