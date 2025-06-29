class Api::V1::ListsController < Api::V1::ApplicationController
    before_action :filter_request

    def index
        @lists = List.where(user_id: @current_user.id, type: params[:type])
        return render json: @lists, status: :ok
    end

    def show
        @list = List.where(id: params[:id], type: params[:type])
        return render json: @list.last, status: :ok
    end

    # def create
    #     return render json: { message: "create" }
    # end

    # def update
    #     return render json: { message: "update" }
    # end

    # def destroy
    #     return render json: { message: "destroy" }
    # end

    private
    def filter_request
        return render json: { message: "#{action_name} action is not allowed for #{list_type}" } unless get_permissions.include?(action_name.to_sym)
    end

    def list_type
        return params[:type].to_sym
    end

    def get_permissions
        PERMISSIONS[list_type]
    end

    PERMISSIONS = {
        DefaultList: [:index, :show],
        CustomList: [:index, :show, :create, :update, :destroy]
    }
end