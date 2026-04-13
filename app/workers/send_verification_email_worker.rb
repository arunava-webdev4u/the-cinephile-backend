class SendVerificationEmailWorker
  include Sidekiq::Worker

  # Non-retryable errors — no point retrying these, discard immediately
  NON_RETRYABLE_ERRORS = [
    SmtpGmailService::ConfigurationError,  # missing/bad SMTP credentials
    SmtpGmailService::EmailError,          # nil user, blank email, etc.
    ActiveRecord::RecordNotFound           # user was deleted before job ran
  ].freeze

  sidekiq_options queue: :mailers, retry: 3

  sidekiq_retry_in do |count|
    # Exponential backoff: 5s → 10s → 20s
    (2**count) * 5
  end

  def perform(user_id)
    user = User.find(user_id)

    registration_details = {
      email:      user.email,
      first_name: user.first_name,
      last_name:  user.last_name,
      otp_code:   user.verification.otp_code
    }

    SmtpGmailService.new.send_verification_email!(registration_details)

  rescue *NON_RETRYABLE_ERRORS => e
    # Log and discard — retrying will not fix these
    Rails.logger.error "[SendVerificationEmailWorker] Non-retryable failure for user_id=#{user_id}: #{e.class} — #{e.message}"
  end
end
