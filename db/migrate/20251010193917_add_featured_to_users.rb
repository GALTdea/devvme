class AddFeaturedToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :featured, :boolean, default: false
    add_column :users, :featured_at, :datetime
    add_index :users, :featured
  end
end
