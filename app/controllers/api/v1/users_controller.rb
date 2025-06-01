class Api::V1::UsersController < Api::V1::ApplicationController
    def index
        @user = User.all
        render json: @user, status: :ok
    end

    
    def create
        # create_params = user_params
        # create_params[:password_digest] = create_params[:password]
        # create_params.delete(:password)

        @user = User.new(user_params)
        if @user.save
            render json: @user, status: :created
        else
            render json: { error: @user.errors.full_message }, status: :unprocessable_entity
        end
    end

    def show
        @user = User.find(params[:id])
        render json: @user, status: :ok
    end

    def update
        # update_params = user_params
        # update_params[:password_digest] = update_params[:password]
        # update_params.delete(:password)

        @user = User.find(params[:id])
        if @user.update(user_params)
            render json: @user, status: :ok
        else
            render json: { error: @user.errors.full_message }, status: :unprocessable_entity
        end
    end

    def delete
        @user = User.find(params[:id])

        render json: { error: @user.errors.full_message }, status: :not_found unless @user
        
        if @user.destroy
            render json: @user, status: :ok
        else
            render json: { error: @user.errors.full_message }, status: :unprocessable_entity
        end
    end

    private
    def user_params
        params.require(:user).permit(:email, :password)
    end
end
