class TrackBlogPostViewJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: 5.seconds, attempts: 3

  def perform(blog_post)
    # Increment view count for the blog post
    blog_post.increment_views!
  rescue => e
    # Log the error but don't fail the job completely
    Rails.logger.error "Failed to track view for blog post #{blog_post.id}: #{e.message}"
    raise e if job_attempts < 3
  end

  private

  def job_attempts
    executions
  end
end
