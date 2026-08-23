# app/controllers/api/v1/auth_controller.rb
class Api::V1::AuthController < Api::V1::BaseController
  skip_before_action :authenticate_user!, only: [ :login, :register, :verify_email ]

  def login
    @user = User.find_by_email(auth_params[:email])
    raise Errors::UnauthorizedError.new("Authentication failed") unless @user&.authenticate(auth_params[:password])

    token = Auth::JsonWebToken.encode({ user_id: @user.id, jti: @user.jti })
    render json: { token: token, user: @user.as_json }, status: :ok
  end

  def register
    raise Errors::BadRequestError.new("Confirmation does not match") if auth_params[:password] != auth_params[:confirm_password]

    user = User.find_by(email: auth_params[:email])

    raise Errors::BadRequestError.new("Account already exists") if user&.verified?

    if user.nil?
      user = User.new(auth_params.except(:confirm_password))
      begin
        user.save!
      rescue ActiveRecord::RecordNotUnique
        user = User.find_by!(email: auth_params[:email])
      end
    end

    verification = user.verification || user.build_verification
    verification.assign_attributes(
      otp_code: UserVerification.generate_otp,
      otp_expires_at: 10.minutes.from_now,
      verified: false,
      verified_at: nil
    )
    verification.save!

    SendVerificationEmailWorker.perform_async(user.id)
    render json: { message: "Please verify your email with the OTP sent" }, status: :created
  end

  def verify_email
    user = User.find_by!(email: params[:email])
    verification = user.verification

    raise Errors::BadRequestError.new("No verification pending") unless verification
    raise Errors::BadRequestError.new("Already verified") if verification.verified?

    if verification.expired? || !verification.match?(params[:otp])
      raise Errors::BadRequestError.new("Invalid or expired code")
    end

    verification.mark_verified!
    token = Auth::JsonWebToken.encode({ user_id: user.id, jti: user.jti })
    SmtpGmailService.new.send_welcome_email(user) if Rails.env.production?
    render json: { token: token, user: user.as_json }, status: :created
  end

  def logout
    @current_user.invalidate_auth_token
    render json: { message: "logged out" }, status: :ok
  end

  private

  def auth_params
    params.require(:user).permit(:email, :password, :confirm_password, :first_name, :last_name, :country, :date_of_birth)
  end
end
