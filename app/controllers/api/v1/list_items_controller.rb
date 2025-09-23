class Api::V1::ListItemsController < Api::V1::ApplicationController
    before_action :set_list

    def index
        render json: { list_items: @list.list_items }, status: :ok
    end

    private
    def set_list
        if params[:type] == "CustomList"
            @list = CustomList.find(params[:custom_list_id])
        elsif params[:type] == "DefaultList"
            @list = DefaultList.find(params[:custom_list_id])
        end
    end
end
