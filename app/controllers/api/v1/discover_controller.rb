class Api::V1::DiscoverController < Api::V1::BaseController
  before_action :initialize_tmdb_service

  def trending
    result = @tmdb_service.trending(discover_params[:type], discover_params[:time_window])

    if result.present?
      render json: result, status: :ok
    else
      render json: { error: "No trending items found" }, status: :not_found
    end
  end

  def popular
    result = @tmdb_service.popular(discover_params[:type])

    if result.present?
      render json: result, status: :ok
    else
      render json: { error: "No popular items found" }, status: :not_found
    end
  end

  def available_today
    result = @tmdb_service.available_today(discover_params[:type])

    if result.present?
      render json: result, status: :ok
    else
      render json: { error: "No available today items found" }, status: :not_found
    end
  end

  def upcoming
    result = @tmdb_service.upcoming(discover_params[:type])

    if result.present?
      render json: result, status: :ok
    else
      render json: { error: "No upcoming items found" }, status: :not_found
    end
  end

  private
  def discover_params
    params.permit(:time_window, :type, :format)
  end
  def initialize_tmdb_service
    @tmdb_service ||= TmdbService.new
  end
end
