class Api::V1::ListsController < Api::V1::ApplicationController
    before_action :filter_request

    def index
        @lists = List.where(user_id: @current_user.id, type: params[:type])
        render json: @lists, status: :ok
    end

    def show
        @list = List.where(id: params[:id], type: params[:type])
        render json: @list.last, status: :ok
    end

    def create
        @list = CustomList.new({ user: @current_user, **list_params })

        if @list.save
            render json: @list, status: :created
        else
            render json: { errors: @list.errors }, status: :unprocessable_entity
        end
    end

    def update
        @list = CustomList.find(params[:id])

        unless @list
            return render json: { error: "List not found" }, status: :not_found
        end

        if @list.update(list_params)
            render json: @list, status: :ok
        else
            render json: { error: @user.errors }, status: :unprocessable_entity
        end
    end

    def destroy
        @list = CustomList.find(params[:id])
        if @list.destroy
            render json: { message: "List deleted successfully" }, status: :ok
        else
            render json: { errors: @list.errors }, status: :unprocessable_entity
        end
    rescue ActiveRecord::RecordNotFound
            render json: { error: "List not found" }, status: :unprocessable_entity
    end

    private
    def list_params
        params.require(:list).permit(:name, :description, :private)
    end

    def filter_request
        render json: { message: "#{action_name} action is not allowed for #{list_type}" } unless get_permissions.include?(action_name.to_sym)
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
