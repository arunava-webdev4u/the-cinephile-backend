class Api::V1::AuthController < Api::V1::BaseController
    skip_before_action :authenticate_user!, only: [ :login, :register, :verify_email ]

    def login
        # puts "========================"
        # puts auth_params
        @user = User.find_by_email(auth_params[:email])
        # puts "========================"
        # puts @user.inspect
        
        # binding.pry
        
        if @user && @user.authenticate(auth_params[:password])
            token = JsonWebToken.encode({ user_id: @user.id, jti: @user.jti })
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
            unless user.save
                return render json: { errors: user.errors }, status: :unprocessable_entity
            end
        end

        verification = user.verification
        if verification.present?
            verification.regenerate!(ttl: 10.minutes)
        else
            verification = user.create_verification_record
        end

        if verification.save!
            SmtpGmailService.new.send_verification_email(user, verification) if Rails.env.production?
            render json: { message: "Please verify your email with the OTP sent" }, status: :ok
        else
            render json: { errors: pending.errors }, status: :unprocessable_entity
        end
    end

    def verify_email
        user = User.find_by(email: params[:email])
        return render json: { error: "No such account" }, status: :not_found unless user

        verification = user.verification
        return render json: { error: "No verification in progress" }, status: :unprocessable_entity unless verification

        if verification.expired? || !verification.match?(params[:otp])
            return render json: { error: "Invalid or expired OTP" }, status: :unprocessable_entity
        end

        verification.mark_verified!
        token = JsonWebToken.encode({ user_id: user.id, jti: user.jti })
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
