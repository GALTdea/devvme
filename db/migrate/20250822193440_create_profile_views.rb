class CreateProfileViews < ActiveRecord::Migration[8.0]
  def change
    create_table :profile_views do |t|
      t.references :user, null: false, foreign_key: true
      t.string :visitor_ip
      t.string :user_agent, limit: 500
      t.string :referrer, limit: 500
      t.datetime :visited_at, null: false

      t.timestamps
    end

    # Add indexes for performance
    add_index :profile_views, [:user_id, :visited_at]
    add_index :profile_views, [:visitor_ip, :user_id, :visited_at]
    add_index :profile_views, :visited_at
  end
end
