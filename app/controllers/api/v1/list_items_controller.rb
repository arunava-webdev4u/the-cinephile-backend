class Api::V1::ListItemsController < Api::V1::ApplicationController
    before_action :set_list

    def index
        list = @current_user.lists.find(@list.id)
        return render json: { error: "List not found" }, status: :not_found if list.nil?

        list_items = list.list_items
        tmdb_data = TmdbService.new.fetch_batch(list_items)

        # Track items with missing TMDB data for logging
        missing_tmdb_indices = []

        items_with_data = list_items.map.with_index do |item, index|
            if tmdb_data[index].nil?
                missing_tmdb_indices << index
                next
            end
            Movies::ListSerializer.new(item, tmdb_data[index]).as_json
        end.compact

        # Log if any TMDB data failed to load
        if missing_tmdb_indices.any?
            Rails.logger.warn(
                "TMDB data missing for #{missing_tmdb_indices.length} of #{list_items.length} list items " +
                "(list_id: #{@list.id}, type: #{@list.type})"
            )
        end

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
        list_item = @list.list_items.find_by(id: params[:id])

        unless list_item
            return render json: { error: "List item not found" }, status: :not_found
        end

        list_item.destroy
        render json: { message: "Item removed from list" }, status: :ok
    end

    private
    def set_list
        valid_types = [ "CustomList", "DefaultList" ]

        unless valid_types.include?(params[:type])
            return render json: {
                error: "Invalid list type",
                valid_types: valid_types
            }, status: :bad_request
        end

        # Extract list ID based on type for clarity and maintainability
        # Routes provide custom_list_id or default_list_id param based on resource
        list_id = params[:type] == "CustomList" ? params[:custom_list_id] : params[:default_list_id]

        # Find the list by type and ID, scoped to current user for authorization
        @list = @current_user.lists.where(type: params[:type]).find_by(id: list_id)

        unless @list
            render json: { error: "List not found" }, status: :not_found
        end
    end

    def list_item_params
        params.require(:list_item).permit(:item_id, :item_type)
    end
end
