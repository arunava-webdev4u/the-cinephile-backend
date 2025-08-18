class Api::V1::AuthController < Api::V1::BaseController
    skip_before_action :authenticate_user!, only: [ :login, :register, :verify_email ]

    def login
        @user = User.find_by_email(auth_params[:email])

        if @user && @user.authenticate(auth_params[:password])
            token = JsonWebToken.encode({ user_id: @user.id, jti: @user.jti })
            render json: { token: token, user: @user.as_json }, status: :ok
        else
            render json: { error: "email or password is incorrect" }, status: :unauthorized
        end
    end

    def register
        return render json: { error: "passwords don't match" }, status: :unprocessable_entity if auth_params[:password] != auth_params[:confirm_password]

        pending_registration = PendingRegistration.find_by(email: auth_params[:email])

        if pending_registration && !pending_registration.verified
            pending_registration.update(otp_code: generate_otp(), otp_expires_at: 10.minutes.from_now)
            SmtpGmailService.new.send_verification_email(pending_registration)
            # SmtpGmailService.new.send_verification_email(pending_registration) if Rails.env.production?
            return render json: { message: "Verification OTP resent to your email" }, status: :ok
        end

        # also check if user is already an active user

        pending_registration = PendingRegistration.new(auth_params.except(:confirm_password))
        pending_registration.otp_code = generate_otp()
        pending_registration.otp_expires_at = 10.minutes.from_now

        if pending_registration.save
            SmtpGmailService.new.send_verification_email(pending_registration)
            # SmtpGmailService.new.send_verification_email(pending_registration) if Rails.env.production?
            render json: { message: "Please verify your email with the OTP sent" }, status: :ok
        else
            render json: { errors: pending.errors }, status: :unprocessable_entity
        end
    end

    def verify_email
        pending_registration = PendingRegistration.find_by(email: params[:email])

        return render json: { error: "No pending registration" }, status: :not_found unless pending_registration
        return render json: { error: "Invalid or expired OTP" }, status: :unprocessable_entity unless pending_registration.otp_code == params[:otp].to_s && pending_registration.otp_expires_at > Time.now

        @user = User.new(
            email: pending_registration.email,
            password: pending_registration.password_digest,
            first_name: pending_registration.first_name,
            last_name: pending_registration.last_name,
            date_of_birth: pending_registration.date_of_birth,
            country: pending_registration.country
        )

        if @user.save
            token = JsonWebToken.encode({ user_id: @user.id, jti: @user.jti })
            pending_registration.update(verified: true)
            SmtpGmailService.new.send_welcome_email(@user) if Rails.env.production?
            render json: { token: token, user: @user.as_json }, status: :created
        else
            render json: { errors: @user.errors }, status: :unprocessable_entity
        end
    end

    def logout
        @current_user.invalidate_auth_token
        render json: { message: "logged out" }, status: :ok
    end

    private
    def auth_params
        params.require(:user).permit(:email, :password, :confirm_password, :first_name, :last_name, :country, :date_of_birth)
    end

    def generate_otp
        rand(100000..999999).to_s
    end
end
