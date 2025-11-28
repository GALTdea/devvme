class AddEditorModeToBlogPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :blog_posts, :editor_mode, :string, default: 'markdown'
    add_index :blog_posts, :editor_mode
  end
end
