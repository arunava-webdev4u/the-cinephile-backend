class Api::V1::ListItemsController < Api::V1::ApplicationController
    before_action :set_list

    def index
        list_items = @list.list_items
        tmdb_data = TmdbService.new.fetch_batch(list_items)

        items_with_data = list_items.map.with_index do |item, index|
            next if tmdb_data[index].nil?
            Movies::ListSerializer.new(item, tmdb_data[index]).as_json
        end.compact

        render json: items_with_data, status: :ok
    end

    def create
        list_item = @list.list_items.new(list_item_params)
        
        if list_item.save
            render json: list_item, status: :created
        else
            render json: { errors: list_item.errors }, status: :unprocessable_entity
        end
    end

    def destroy
        list_item = @list.list_items.find(params[:id])
        list_item.destroy
        render json: { message: "Item removed from list" }, status: :ok
    end

    private
    def set_list
        if params[:type] == "CustomList"
            @list = CustomList.find(params[:custom_list_id])
        elsif params[:type] == "DefaultList"
            @list = DefaultList.find(params[:custom_list_id])
        end
    end

    def list_item_params
        params.require(:list_item).permit(:item_id, :item_type)
    end
end
