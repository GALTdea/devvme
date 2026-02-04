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
#  mode               :string           default("profile_builder"), not null
#  question_count     :integer          default(0), not null
#  result_data        :jsonb            not null
#  status             :string           default("draft"), not null
#  target_data        :jsonb            not null
#  target_type        :string
#  context_version    :integer          default(1), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  user_id            :bigint           not null
#
# Indexes
#
#  index_architect_sessions_on_mode                    (mode)
#  index_architect_sessions_on_status                  (status)
#  index_architect_sessions_on_target_type             (target_type)
#  index_architect_sessions_on_user_id                 (user_id)
#  index_architect_sessions_on_user_id_and_created_at  (user_id,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class ArchitectSession < ApplicationRecord
  attr_accessor :pasted_content

  MODES = %w[profile_builder fit_gap mock_interview outreach].freeze
  TARGET_TYPES = %w[job_description linkedin_profile company_profile].freeze

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

  enum :mode, MODES.index_with(&:itself), prefix: true

  validates :goal, presence: true
  validates :mode, inclusion: { in: MODES }
  validates :target_type, inclusion: { in: TARGET_TYPES }, allow_nil: true
  validates :generated_bio, length: { maximum: 500 }, allow_blank: true
  validates :generated_headline, length: { maximum: 200 }, allow_blank: true
  validates :question_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :context_version, numericality: { only_integer: true, greater_than_or_equal_to: 1 }

  scope :recent, -> { order(created_at: :desc) }
  scope :for_user, ->(user) { where(user: user) }

  # Context snapshot stores profile + projects + pasted content for LLM context
  def context_snapshot
    super.presence || {}
  end

  def target_data
    super.presence || {}
  end

  def result_data
    super.presence || {}
  end
end
