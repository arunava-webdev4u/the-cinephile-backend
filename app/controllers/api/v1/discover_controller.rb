class Api::V1::DiscoverController < Api::V1::BaseController
  before_action :initialize_tmdb_service
  before_action :force_json_request

  rescue_from TmdbService::TmdbError, with: :handle_tmdb_error

  def trending
    result = @tmdb_service.trending("movie", "week")

    if result.present?
      render json: result, status: :ok
    else
      render json: { error: "No trending movies found" }, status: :not_found
    end
  end

#   def popular
#     result = @tmdb_service.lists("movie", "popular")

#     if result.present?
#       render json: result, status: :ok
#     else
#       render json: { error: "No popular movies found" }, status: :not_found
#     end
#   end

#   def top_rated
#     result = @tmdb_service.lists("movie", "top_rated")

#     if result.present?
#       render json: result, status: :ok
#     else
#       render json: { error: "No top_rated movies found" }, status: :not_found
#     end
#   end

#   def upcoming
#     result = @tmdb_service.lists("movie", "upcoming")

#     if result.present?
#       render json: result, status: :ok
#     else
#       render json: { error: "No upcoming movies found" }, status: :not_found
#     end
#   end

#   def now_playing
#     result = @tmdb_service.lists("movie", "now_playing")

#     if result.present?
#       render json: result, status: :ok
#     else
#       render json: { error: "No now_playing movies found" }, status: :not_found
#     end
#   end

  private
  def initialize_tmdb_service
    @tmdb_service ||= TmdbService.new
  end

  def handle_tmdb_error(exception)
    Rails.logger.error "TMDB API error: #{exception.message}"
    render json: { error: "External service unavailable", details: exception.message },
           status: :service_unavailable
  end

  def force_json_request
    request.format = :json
  end
end
