# app/controllers/api/v1/user_controller.rb
class Api::V1::UserController < Api::V1::BaseController
    def show
        render json: @current_user.as_json, status: :ok
    end

    def update
        @current_user.update!(user_params)
        render json: @current_user, status: :ok
    end

    def destroy
        @current_user.destroy!
        render json: { message: "User deleted successfully" }, status: :ok
    end

    private

    def user_params
        params.require(:user).permit(:email, :first_name, :last_name, :country, :date_of_birth)
    end
end
