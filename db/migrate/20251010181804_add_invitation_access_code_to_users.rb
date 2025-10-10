class AddInvitationAccessCodeToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :invitation_access_code, :string
    add_index :users, :invitation_access_code
  end
end
