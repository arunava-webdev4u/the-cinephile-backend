class Api::V1::AuthController < Api::V1::BaseController
    skip_before_action :authenticate_user!, only: [ :login, :register, :verify_email ]

    def login
        @user = User.find_by_email(auth_params[:email])

        if @user && @user.authenticate(auth_params[:password])
            token = Auth::JsonWebToken.encode({ user_id: @user.id, jti: @user.jti })
            render json: { token: token, user: @user.as_json }, status: :ok
        else
            render json: { error: "email or password is incorrect" }, status: :unauthorized
        end
    end

    def register
        return render json: { error: "passwords don't match" }, status: :unprocessable_entity if auth_params[:password] != auth_params[:confirm_password]

        user = User.find_by(email: auth_params[:email])

        if user&.verified?
            return render json: { error: "Account already exists and is verified" }, status: :unprocessable_entity
        end

        if user.nil?    # user does not exist
            user = User.new(auth_params.except(:confirm_password))
            return render json: { errors: user.errors }, status: :unprocessable_entity unless user.valid?

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

        if verification.save
            SendVerificationEmailWorker.perform_async(user.id)
            render json: { message: "Please verify your email with the OTP sent" }, status: :created
        else
            render json: { errors: verification.errors }, status: :unprocessable_entity
        end
    end

    def verify_email
        user = User.find_by(email: params[:email])
        return render json: { error: "Account not found" }, status: :not_found unless user

        verification = user.verification
        return render json: { error: "No verification in progress" }, status: :unprocessable_entity unless verification

        return render json: { error: "Already verified" }, status: :unprocessable_entity if verification.verified?

        if verification.expired? || !verification.match?(params[:otp])
            return render json: { error: "Invalid or expired OTP" }, status: :unprocessable_entity
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

    def generate_otp
        rand(100000..999999).to_s
    end
end
