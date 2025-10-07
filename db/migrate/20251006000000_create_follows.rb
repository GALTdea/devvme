class CreateFollows < ActiveRecord::Migration[7.2]
  def change
    create_table :follows do |t|
      t.references :follower, null: false, foreign_key: { to_table: :users }
      t.references :followee, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end

    add_index :follows, [:follower_id, :followee_id], unique: true, if_not_exists: true
    add_index :follows, :follower_id, if_not_exists: true
    add_index :follows, :followee_id, if_not_exists: true
  end
end
