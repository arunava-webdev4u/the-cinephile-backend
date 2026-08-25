# app/workers/send_password_reset_email_worker.rb
class SendPasswordResetEmailWorker
  include Sidekiq::Worker

  # Non-retryable errors — no point retrying these, discard immediately
  NON_RETRYABLE_ERRORS = [
    SmtpGmailService::ConfigurationError,
    SmtpGmailService::EmailError,
    ActiveRecord::RecordNotFound
  ].freeze

  sidekiq_options queue: :mailers, retry: 3

  sidekiq_retry_in do |count|
    # Exponential backoff: 5s → 10s → 20s
    (2**count) * 5
  end

  def perform(user_id)
    user = User.find(user_id)

    reset_details = {
      email:      user.email,
      first_name: user.first_name,
      otp_code:   user.verification.otp_code
    }

    SmtpGmailService.new.send_password_reset_email!(reset_details)

  rescue *NON_RETRYABLE_ERRORS => e
    Rails.logger.error "[SendPasswordResetEmailWorker] Non-retryable failure for user_id=#{user_id}: #{e.class} — #{e.message}"
  end
end
