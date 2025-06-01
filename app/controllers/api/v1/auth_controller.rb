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
        return render json: { error: "passwords don't match"}, status: :unprocessable_entity if user_params[:password] != user_params[:confirm_password]
        @user = User.new(user_params.except(:confirm_password))
        
        if @user.save
            token = JsonWebToken.encode({ user_id: @user.id })
            render json: { token: token, user: { id: @user.id, email: @user.email} }, status: :created
        else
            render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
    end

    private
    def user_params
        params.require(:user).permit(:email, :password, :confirm_password)
    end
end
