class AddProfileFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :job_title, :string
    add_column :users, :location, :string
    add_column :users, :twitter_url, :string
    add_column :users, :resume_url, :string
    add_column :users, :contact_email, :string
    add_column :users, :phone, :string
    add_column :users, :headline, :text
    add_column :users, :skills, :json
  end
end
