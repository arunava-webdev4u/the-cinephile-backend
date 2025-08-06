class Api::V1::SearchController < Api::V1::BaseController
  before_action :initialize_tmdb_service
  
  def name
    render json: { error: "Parameters are missing" }, status: :bad_request unless check_params(params)
    
    type = params[:type]
    query = params[:query]

    result = tmdb_service.search_by_name(query, type)

    # if query.present?
    #   @movies = tmdb_service.search_movies(query)
    #   render json: @movies
    # else
    # end
    render json: { query: query, type: type, result: result }
  end

  def id
    render json: { error: "Parameters are missing" }, status: :bad_request unless check_params(params)
    type = params[:type]
    tmdb_id = params[:tmdb_id]

    result = tmdb_service.search_by_id(tmdb_id, type)
    render json: { tmdb_id: tmdb_id, type: type, result: result }

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

  def initialize_tmdb_service
    @tmdb_service ||= TmdbService.new
  end

  def tmdb_service
    @tmdb_service
  end

  def check_params(params)
    if params[:type].present?
      return params[:query].present? || params[:tmdb_id].present?
    end
    return false
  end


end
