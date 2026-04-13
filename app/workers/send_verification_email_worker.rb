class SendVerificationEmailWorker
  include Sidekiq::Worker

  sidekiq_options queue: :mailers, retry: 3

  def perform(user_id)
    user = User.find(user_id)
    registration_details = {
      email:      user.email,
      first_name: user.first_name,
      last_name:  user.last_name,
      otp_code:   user.verification.otp_code
    }
    SmtpGmailService.new.send_verification_email(registration_details)
  end
end