class AddSocialCardTypeToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :social_card_type, :string, default: 'professional', null: false
    add_index :users, :social_card_type
  end
end
