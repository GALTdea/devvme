class CreateBlogPosts < ActiveRecord::Migration[8.0]
  def change
    create_table :blog_posts do |t|
      t.string :title, null: false
      t.text :content, null: false
      t.text :excerpt
      t.boolean :published, default: false, null: false
      t.datetime :published_at
      t.string :slug, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :blog_posts, :slug, unique: true
    add_index :blog_posts, :published
    add_index :blog_posts, :published_at
    add_index :blog_posts, [:user_id, :published]
    add_index :blog_posts, [:published, :published_at]
  end
end
