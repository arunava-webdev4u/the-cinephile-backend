class Api::V1::DiscoverController < Api::V1::BaseController
  before_action :initialize_tmdb_service

  rescue_from TmdbService::TmdbError, with: :handle_tmdb_error
  rescue_from ArgumentError, with: :handle_invalid_params

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

  def handle_tmdb_error(exception)
    Rails.logger.error "TMDB API error: #{exception.message}"
    render json: { error: "External service unavailable", details: exception.message },
           status: :service_unavailable
  end

  def handle_invalid_params(exception)
    render json: {
      error: exception.message,
      valid_types: %w[all movie person tv],
      valid_time_windows: %w[day week]
    }, status: :bad_request
  end
end
