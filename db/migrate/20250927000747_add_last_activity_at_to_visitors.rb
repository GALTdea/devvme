class AddLastActivityAtToVisitors < ActiveRecord::Migration[8.0]
  def change
    add_column :visitors, :last_activity_at, :datetime
    add_index :visitors, :last_activity_at

    # Backfill existing records - set last_activity_at to last_visit_at
    # This ensures existing data works with the new tracking logic
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE visitors
          SET last_activity_at = last_visit_at
          WHERE last_activity_at IS NULL
        SQL
      end
    end
  end
end
