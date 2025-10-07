class SendWeeklyDigestsJob < ApplicationJob
  queue_as :mailers

  def perform
    Rails.logger.info "Starting weekly digest job at #{Time.current}"

    # Find users who should receive weekly digests
    users = User.joins(:digest_preference)
                .where(digest_preferences: {
                  frequency: :weekly,
                  enabled: true
                })
                .where('digest_preferences.next_send_at <= ?', Time.current)
                .includes(:digest_preference)

    Rails.logger.info "Found #{users.count} users due for weekly digest"

    processed_count = 0
    error_count = 0

    users.find_each do |user|
      begin
        SendUserDigestJob.perform_later(user.id, 'weekly')
        processed_count += 1

        # Small delay to prevent overwhelming the system
        sleep(0.1) if processed_count % 10 == 0
      rescue => e
        Rails.logger.error "Failed to queue digest for user #{user.id}: #{e.message}"
        error_count += 1
      end
    end

    Rails.logger.info "Weekly digest job completed. Processed: #{processed_count}, Errors: #{error_count}"
  end
end
