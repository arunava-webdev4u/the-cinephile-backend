class Api::V1::UsersController < Api::V1::ApplicationController
    def index
        @user = User.all
        render json: @user.as_json, status: :ok
    end

    def show
        @user = User.find(params[:id])
        render json: @user.as_json, status: :ok
    end

    def update
        @user = User.find(params[:id])
        if @user.update(user_params)
            render json: @user, status: :ok
        else
            render json: { error: @user.errors.full_message }, status: :unprocessable_entity
        end
    end

    def destroy
        @user = User.find_by(id: params[:id])

        unless @user
            render json: { error: "User not found" }, status: :not_found
            return
        end

        if @user.destroy
            render json: { message: "User deleted successfully" }, status: :ok
        else
            render json: { error: @user.errors.full_messages }, status: :unprocessable_entity
        end
    end

    private
    def user_params
        params.require(:user).permit(:email, :first_name, :last_name, :country, :date_of_birth)
    end
end
