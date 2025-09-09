class Api::V1::SearchController < Api::V1::BaseController
  before_action :initialize_tmdb_service
  before_action :validate_search_params, only: [ :name, :id ]

  def name
    result = @tmdb_service.search_by_name(search_params[:query], search_params[:type])

    render json: { query: search_params[:query], type: search_params[:type], result: result }, status: :ok
  end

  def id
    result = @tmdb_service.search_by_id(search_params[:tmdb_id], search_params[:type])

    render json: { result: result }, status: :ok
  end

  def trending
      # @trending_movies = tmdb_service.trending_movies

      # if @trending_movies.present?
      #   render json: @trending_movies
      # else
      #   render json: { error: "No trending_movies movies found" }, status: :not_found
      # end
      render json: { message: "trending" }
  end

  def popular
    # @popular = tmdb_service.popular

    # if @popular.present?
    #   render json: @popular
    # else
    #   render json: { error: "No popular movies found" }, status: :not_found
    # end
    render json: { message: "popular" }
  end

  def top_rated
    # @top_rated = tmdb_service.top_rated

    # if @top_rated.present?
    #   render json: @top_rated
    # else
    #   render json: { error: "No top_rated movies found" }, status: :not_found
    # end
    render json: { message: "top_rated" }
  end

  def upcoming
    # @upcoming = tmdb_service.upcoming

    # if @upcoming.present?
    #   render json: @upcoming
    # else
    #   render json: { error: "No upcoming movies found" }, status: :not_found
    # end
    render json: { message: "upcoming" }
  end

  def now_playing
    # @now_playing = tmdb_service.now_playing

    # if @now_playing.present?
    #   render json: @now_playing
    # else
    #   render json: { error: "No now_playing movies found" }, status: :not_found
    # end
    render json: { message: "now_playing" }
  end

  private
  def initialize_tmdb_service
    @tmdb_service ||= TmdbService.new
  end

  def search_params
    params.permit(:query, :tmdb_id, :type)
  end

  def validate_search_params
    unless params[:type].present?
      render json: {
        success: false,
        error: "Type parameter is required",
        valid_types: TmdbService::VALID_SEARCH_TYPES
      }, status: :bad_request
      return
    end

    if params[:query].blank? && params[:tmdb_id].blank?
      render json: {
        success: false,
        error: "Either query or tmdb_id parameter is not present"
      }, status: :bad_request
      nil
    end
  end
end
