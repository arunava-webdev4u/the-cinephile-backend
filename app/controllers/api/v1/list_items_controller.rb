# app/controllers/api/v1/list_items_controller.rb
class Api::V1::ListItemsController < Api::V1::BaseController
    before_action :set_list

    def index
        list_items = @list.list_items
        tmdb_data = TmdbService.new.fetch_batch(list_items)

        missing_tmdb_indices = []

        items_with_data = list_items.map.with_index do |item, index|
            if tmdb_data[index].nil?
                missing_tmdb_indices << index
                next
            end
            Movies::ListSerializer.new(item, tmdb_data[index]).as_json
        end.compact

        if missing_tmdb_indices.any?
            Rails.logger.warn(
                "TMDB data missing for #{missing_tmdb_indices.length} of #{list_items.length} list items " +
                "(list_id: #{@list.id}, type: #{@list.type})"
            )
        end

        render json: items_with_data, status: :ok
    end

    def create
        list_item = @list.list_items.create!(list_item_params)
        render json: list_item, status: :created
    end

    def destroy
        list_item = @list.list_items.find(params[:id])
        list_item.destroy!
        render json: { message: "Item removed from list" }, status: :ok
    end

    private

    def set_list
        valid_types = [ "CustomList", "DefaultList" ]

        unless valid_types.include?(params[:type])
            raise Errors::BadRequestError.new("Invalid list type. Valid types: #{valid_types.join(', ')}")
        end

        list_id = params[:type] == "CustomList" ? params[:custom_list_id] : params[:default_list_id]

        # find_by! raises RecordNotFound → global handler returns 404
        @list = @current_user.lists.where(type: params[:type]).find_by!(id: list_id)
    end

    def list_item_params
        params.require(:list_item).permit(:item_id, :item_type)
    end
end
