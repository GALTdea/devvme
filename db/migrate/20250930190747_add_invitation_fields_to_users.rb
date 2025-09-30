class AddInvitationFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    # Add invitation-related fields
    add_column :users, :invitation_token, :string
    add_column :users, :invitation_sent_at, :datetime
    add_column :users, :invitation_accepted_at, :datetime

    # Add indexes for performance
    add_index :users, :invitation_token, unique: true
    add_index :users, :invitation_sent_at
    add_index :users, :invitation_accepted_at

    # Update account_status enum to include 'invited' status
    # We need to add the new enum value between existing ones
    # Current: pending_activation: 0, active: 1, suspended: 2, deactivated: 3
    # New: pending_activation: 0, invited: 1, active: 2, suspended: 3, deactivated: 4

    # First, update existing records to shift their status values
    execute <<-SQL
      UPDATE users
      SET account_status = CASE
        WHEN account_status >= 1 THEN account_status + 1
        ELSE account_status
      END;
    SQL
  end

  def down
    # Revert the account_status changes
    execute <<-SQL
      UPDATE users
      SET account_status = CASE
        WHEN account_status > 1 THEN account_status - 1
        ELSE account_status
      END;
    SQL

    # Remove indexes
    remove_index :users, :invitation_token
    remove_index :users, :invitation_sent_at
    remove_index :users, :invitation_accepted_at

    # Remove columns
    remove_column :users, :invitation_token
    remove_column :users, :invitation_sent_at
    remove_column :users, :invitation_accepted_at
  end
end
