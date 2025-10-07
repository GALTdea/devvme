class SendMonthlyDigestsJob < ApplicationJob
  queue_as :mailers

  def perform
    Rails.logger.info "Starting monthly digest job at #{Time.current}"

    # Find users who should receive monthly digests
    users = User.joins(:digest_preference)
                .where(digest_preferences: {
                  frequency: :monthly,
                  enabled: true
                })
                .where("digest_preferences.next_send_at <= ?", Time.current)
                .includes(:digest_preference)

    Rails.logger.info "Found #{users.count} users due for monthly digest"

    processed_count = 0
    error_count = 0

    users.find_each do |user|
      begin
        SendUserDigestJob.perform_later(user.id, "monthly")
        processed_count += 1

        # Small delay to prevent overwhelming the system
        sleep(0.1) if processed_count % 10 == 0
      rescue => e
        Rails.logger.error "Failed to queue digest for user #{user.id}: #{e.message}"
        error_count += 1
      end
    end

    Rails.logger.info "Monthly digest job completed. Processed: #{processed_count}, Errors: #{error_count}"
  end
end
