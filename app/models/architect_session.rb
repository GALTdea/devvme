# == Schema Information
#
# Table name: architect_sessions
# Database name: primary
#
#  id                 :bigint           not null, primary key
#  context_snapshot   :jsonb
#  generated_bio      :text
#  generated_headline :text
#  goal               :string           not null
#  question_count     :integer          default(0), not null
#  status             :string           default("draft"), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  user_id            :bigint           not null
#
# Indexes
#
#  index_architect_sessions_on_status                  (status)
#  index_architect_sessions_on_user_id                 (user_id)
#  index_architect_sessions_on_user_id_and_created_at  (user_id,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class ArchitectSession < ApplicationRecord
  attr_accessor :pasted_content

  belongs_to :user
  has_many :architect_messages, dependent: :destroy

  enum :status, {
    draft: "draft",
    in_progress: "in_progress",
    completed: "completed",
    abandoned: "abandoned"
  }, default: :draft

  enum :goal, {
    bio: "bio",
    headline: "headline",
    both: "both"
  }, prefix: true

  validates :goal, presence: true
  validates :generated_bio, length: { maximum: 500 }, allow_blank: true
  validates :generated_headline, length: { maximum: 200 }, allow_blank: true
  validates :question_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :recent, -> { order(created_at: :desc) }
  scope :for_user, ->(user) { where(user: user) }

  # Context snapshot stores profile + projects + pasted content for LLM context
  def context_snapshot
    super.presence || {}
  end
end
