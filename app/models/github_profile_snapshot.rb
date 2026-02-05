# frozen_string_literal: true

# == Schema Information
#
# Table name: github_profile_snapshots
# Database name: primary
#
#  id         :bigint           not null, primary key
#  fetched_at :datetime
#  payload    :jsonb            not null
#  username   :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_github_profile_snapshots_on_user_id   (user_id) UNIQUE
#  index_github_profile_snapshots_on_username  (username)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class GitHubProfileSnapshot < ApplicationRecord
  belongs_to :user

  validates :username, presence: true
  validates :payload, presence: true
end
