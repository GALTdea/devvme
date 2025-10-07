class CreateUserDigestPreferences < ActiveRecord::Migration[7.2]
  def change
    create_table :user_digest_preferences do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :frequency, default: 2, null: false # 0=daily, 1=biweekly, 2=weekly, 3=monthly, 4=never
      t.boolean :enabled, default: true, null: false
      t.datetime :last_sent_at
      t.datetime :next_send_at
      t.boolean :include_blog_posts, default: true, null: false
      t.boolean :include_projects, default: true, null: false
      t.boolean :include_profile_updates, default: false, null: false
      t.time :digest_time, default: '08:00', null: false # Preferred time to send (24-hour format)
      t.string :timezone, default: 'UTC', null: false
      t.timestamps
    end

    add_index :user_digest_preferences, :user_id, unique: true, if_not_exists: true
    add_index :user_digest_preferences, [:frequency, :enabled, :next_send_at], if_not_exists: true
    add_index :user_digest_preferences, :next_send_at, if_not_exists: true
  end
end
