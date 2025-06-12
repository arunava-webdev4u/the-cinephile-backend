class Api::V1::AuthController < Api::V1::BaseController
    skip_before_action :authenticate_user!, only: [:login, :register]

    def login
        @user = User.find_by_email(auth_params[:email])

        if @user && @user.authenticate(auth_params[:password])
            token = JsonWebToken.encode({ user_id: @user.id })
            render json: { token: token, user: { id: @user.id, email: @user.email } }, status: :ok
        else
            render json: { error: "email or password is incorrect" }
        end
    end

    def register
        return render json: { error: "passwords don't match" }, status: :unprocessable_entity if auth_params[:password] != auth_params[:confirm_password]
        @user = User.new(auth_params.except(:confirm_password))

        if @user.save
            token = JsonWebToken.encode({ user_id: @user.id })
            render json: { token: token, user: { id: @user.id, email: @user.email } }, status: :created
        else
            render json: { errors: @user.errors }, status: :unprocessable_entity
        end
    end

    private
    def auth_params
        params.require(:user).permit(:email, :password, :confirm_password, :first_name, :last_name, :country, :date_of_birth)
    end
end
