# app/controllers/api/v1/lists_controller.rb
class Api::V1::ListsController < Api::V1::BaseController
    before_action :filter_request

    def index
        @lists = List.where(user_id: @current_user.id, type: params[:type])
        render json: @lists, status: :ok
    end

    def show
        @list = List.find_by!(id: params[:id], type: params[:type], user_id: @current_user.id)
        render json: @list, status: :ok
    end

    def create
        @list = CustomList.create!({ user: @current_user, **list_params })
        render json: @list, status: :created
    end

    def update
        @list = CustomList.find_by!(id: params[:id], user_id: @current_user.id)
        @list.update!(list_params)
        render json: @list, status: :ok
    end

    def destroy
        @list = CustomList.find_by!(id: params[:id], user_id: @current_user.id)
        @list.destroy!
        render json: { message: "List deleted successfully" }, status: :ok
    end

    private

    def list_params
        params.require(:list).permit(:name, :description, :private)
    end

    def filter_request
        unless get_permissions.include?(action_name.to_sym)
            raise Errors::ForbiddenError.new("#{action_name} is not allowed for #{list_type}")
        end
    end

    def list_type
        params[:type].to_sym
    end

    def get_permissions
        PERMISSIONS[list_type]
    end

    PERMISSIONS = {
        DefaultList: [ :index, :show ],
        CustomList: [ :index, :show, :create, :update, :destroy ]
    }
end
