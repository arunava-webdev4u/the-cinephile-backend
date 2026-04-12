class SendVerificationEmailWorker
  include Sidekiq::Worker

  sidekiq_options queue: :mailers, retry: 3

  def perform(registration_details)
    # Sidekiq serializes args as JSON, so symbol keys become string keys.
    # deep_symbolize_keys restores the expected format for SmtpGmailService.
    SmtpGmailService.new.send_verification_email(registration_details.deep_symbolize_keys)
  end
end