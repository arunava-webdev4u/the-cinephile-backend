class Api::V1::UserController < Api::V1::ApplicationController
    # def index
    #     @user = User.all
    #     render json: @user.as_json, status: :ok
    # end

    def show
        render json: @current_user.as_json, status: :ok
    end

    def update
        if @current_user.update(user_params)
            render json: @current_user, status: :ok
        else
            render json: { errors: @current_user.errors }, status: :unprocessable_entity
        end
    end

    def destroy
        if @current_user.destroy
            render json: { message: "User deleted successfully" }, status: :ok
        else
            render json: { errors: @current_user.errors }, status: :unprocessable_entity
        end
    end

    private
    def user_params
        params.require(:user).permit(:email, :first_name, :last_name, :country, :date_of_birth)
    end
end
