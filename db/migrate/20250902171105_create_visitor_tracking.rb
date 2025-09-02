class CreateVisitorTracking < ActiveRecord::Migration[8.0]
  def change
    # Visitors table - tracks unique visitors
    create_table :visitors do |t|
      t.string :visitor_id, null: false, index: { unique: true }
      t.string :ip_address
      t.string :user_agent, limit: 500
      t.string :referrer, limit: 500
      t.string :country
      t.string :city
      t.datetime :first_visit_at, null: false
      t.datetime :last_visit_at, null: false
      t.integer :visit_count, default: 1
      t.integer :page_views, default: 0
      t.integer :total_time_on_site, default: 0 # in seconds
      t.boolean :converted, default: false
      t.bigint :user_id, null: true, index: true
      t.timestamps

      t.index [:visitor_id, :first_visit_at]
      t.index [:converted]
      t.index [:first_visit_at]
      t.index [:last_visit_at]
    end

    # Page views table - tracks individual page visits
    create_table :visitor_page_views do |t|
      t.references :visitor, null: false, foreign_key: true
      t.string :page_path, null: false
      t.string :page_title
      t.string :referrer, limit: 500
      t.integer :time_on_page, default: 0 # in seconds
      t.datetime :viewed_at, null: false
      t.timestamps

      t.index [:visitor_id, :viewed_at]
      t.index [:page_path, :viewed_at]
      t.index [:viewed_at]
    end

    add_foreign_key :visitors, :users, column: :user_id
  end
end
