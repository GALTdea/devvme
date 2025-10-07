class Follow < ApplicationRecord
  belongs_to :follower, class_name: "User"
  belongs_to :followee, class_name: "User"

  validates :follower_id, presence: true
  validates :followee_id, presence: true
  validates :follower_id, uniqueness: { scope: :followee_id }
  validate :cannot_follow_self

  private

  def cannot_follow_self
    if follower_id == followee_id
      errors.add(:followee_id, "cannot be the same as follower")
    end
  end
end
