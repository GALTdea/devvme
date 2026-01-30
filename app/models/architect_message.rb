# == Schema Information
#
# Table name: architect_messages
#
#  id                   :bigint           not null, primary key
#  architect_session_id :bigint           not null
#  role                 :string           not null
#  content              :text             not null
#  sequence             :integer          not null
#  topic                :string
#  insight_type         :string
#  metadata             :jsonb            default({}), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
# Indexes
#
#  index_architect_messages_on_architect_session_id  (architect_session_id)
#  index_architect_messages_on_architect_session_id_and_sequence  (architect_session_id,sequence) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (architect_session_id => architect_sessions.id)
#
class ArchitectMessage < ApplicationRecord
  belongs_to :architect_session

  enum :role, {
    user: "user",
    assistant: "assistant"
  }, prefix: :message

  validates :content, presence: true
  validates :sequence, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :sequence, uniqueness: { scope: :architect_session_id }

  scope :ordered, -> { order(:sequence) }

  # Metadata for future training data / Agentic Twin use
  def metadata
    super.presence || {}
  end
end
