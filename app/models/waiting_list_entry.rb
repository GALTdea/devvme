class WaitingListEntry < ApplicationRecord
  # Associations
  belongs_to :user, optional: true

  # Status enum - tracks the lifecycle of a waiting list entry
  enum :status, {
    pending: 0,      # Initial state - waiting for approval
    invited: 1,      # Admin has sent invitation to user
    converted: 2,    # Successfully converted to active user
    declined: 3      # User declined or invitation expired
  }

  # Validations
  validates :email, presence: true,
                   format: { with: URI::MailTo::EMAIL_REGEXP },
                   uniqueness: { case_sensitive: false, scope: :status,
                               conditions: -> { where(status: [:pending, :invited]) },
                               message: 'is already on the waiting list' }

  validates :full_name, length: { maximum: 100 }
  validates :source, length: { maximum: 100 }

  # Scopes
  scope :pending, -> { where(status: :pending) }
  scope :invited, -> { where(status: :invited) }
  scope :converted, -> { where(status: :converted) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_position, -> { order(position: :asc) }

  # Callbacks
  before_create :assign_position
  # Note: Confirmation email callback disabled until mailer is implemented
  # after_create :send_confirmation_email

  # Instance methods
  def approve_and_invite!(admin:)
    transaction do
      # Create user with invited status
      new_user = User.new(
        email: email,
        full_name: full_name,
        username: generate_username,
        account_status: :invited
      )

      # Skip password validation for invited users
      new_user.save!(validate: false)

      # Send invitation using existing system
      new_user.invite!(admin: admin, send_email: true)

      # Update waiting list entry
      update!(
        status: :invited,
        user_id: new_user.id,
        notified_at: Time.current
      )

      new_user
    end
  rescue => e
    Rails.logger.error "Failed to approve waiting list entry #{id}: #{e.message}"
    raise
  end

  def mark_as_converted!
    update!(status: :converted, converted_at: Time.current)
  end

  def mark_as_declined!
    update!(status: :declined)
  end

  private

  def assign_position
    return if position.present?

    max_position = WaitingListEntry.pending.maximum(:position) || 0
    self.position = max_position + 1
  end

  def generate_username
    # Generate username from email or full_name
    base_username = if full_name.present?
                     full_name.downcase.gsub(/[^a-z0-9]/, '_')
                   else
                     email.split('@').first.downcase.gsub(/[^a-z0-9]/, '_')
                   end

    # Ensure uniqueness
    username = base_username
    counter = 1
    while User.exists?(username: username)
      username = "#{base_username}#{counter}"
      counter += 1
    end

    username
  end

  # Uncomment when mailer is ready
  # def send_confirmation_email
  #   WaitingListMailer.confirmation(self).deliver_later
  # rescue => e
  #   Rails.logger.error "Failed to send waiting list confirmation email to #{email}: #{e.message}"
  # end
end
