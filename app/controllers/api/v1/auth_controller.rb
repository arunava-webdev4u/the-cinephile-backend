class Api::V1::AuthController < Api::V1::BaseController
    def login
        render json: { message: "login" }
        # user = User.find(email: params[:email])
        # if user & user.authenticate(params[:password])
        #     token = JsonWebToken.encode(user_id: user.id)
        #     render json: { token: token, user: { id: user.id, email: user.email } }, status: :ok
        # else
        #     render json: { error: "Invalid email or password" }, status: :unauthorized
        # end
    end

    def register
        puts "==================="
        puts params[:user]

        # @user = User.new(email: params[:user][:email], password_digest: params[:user][:password])

        render json: { message: "register" }
        # user = User.new()
    end

    private
    def user_params
        params.permit(:email, :password, :confirm_password)
    end
end
