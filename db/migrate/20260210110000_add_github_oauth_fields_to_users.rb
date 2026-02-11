class AddGitHubOauthFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :github_oauth_token, :text
    add_column :users, :github_oauth_scope, :string
    add_column :users, :github_oauth_connected_at, :datetime

    add_index :users, :github_oauth_connected_at
  end
end
