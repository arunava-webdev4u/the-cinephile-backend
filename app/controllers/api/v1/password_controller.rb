# app/controllers/api/v1/password_controller.rb
class Api::V1::PasswordController < Api::V1::BaseController
  skip_before_action :authenticate_user!, only: [ :forgot, :reset ]

  def forgot
    user = User.find_by!(email: params[:email])
    raise Errors::ForbiddenError.new("Account is not verified") unless user.email_verified?

    verification = user.verification || user.build_verification
    verification.assign_attributes(
      otp_code: UserVerification.generate_otp,
      otp_expires_at: 10.minutes.from_now
      # verified_at is intentionally preserved — it records that the
      # account's email was verified at some point, independent of the
      # current OTP flow state.
    )
    verification.save!

    SendPasswordResetEmailWorker.perform_async(user.id)

    render json: { message: "If the email is registered, a reset code has been sent" }, status: :ok
  end

  def reset
    user = User.find_by!(email: params[:email])
    raise Errors::ForbiddenError.new("Account is not verified") unless user.email_verified?

    verification = user.verification

    raise Errors::BadRequestError.new("No reset requested") unless verification
    raise Errors::BadRequestError.new("Invalid or expired code") if verification.expired? || !verification.match?(params[:otp])
    raise Errors::BadRequestError.new("Confirmation does not match") if params[:password] != params[:confirm_password]

    user.update!(
      password: params[:password],
      password_confirmation: params[:confirm_password]
    )

    # Consume the OTP so it cannot be reused
    verification.regenerate!(ttl: 0.seconds)

    # Invalidate all existing JWTs for this user
    user.invalidate_auth_token

    render json: { message: "Password has been reset successfully" }, status: :ok
  end
end
