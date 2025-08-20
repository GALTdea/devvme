class UpdateProjectsForCrud < ActiveRecord::Migration[8.0]
  def change
    # Add missing fields according to requirements
    add_column :projects, :live_url, :string
    add_column :projects, :source_code_url, :string
    add_column :projects, :display_order, :integer

    # Convert technologies text field to technologies_used JSON field
    add_column :projects, :technologies_used, :json, default: []

    # Add indexes for performance
    add_index :projects, :display_order
    add_index :projects, :status
    add_index :projects, [:user_id, :display_order]

    # Remove old technologies field (will be done after data migration if needed)
    # remove_column :projects, :technologies, :text
  end
end
