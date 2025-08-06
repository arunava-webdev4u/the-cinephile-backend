class Api::V1::SearchController < Api::V1::BaseController
  def index
    query = params[:query]
    # if query.present?
    #   @movies = tmdb_service.search_movies(query)
    #   render json: @movies
    # else
    #   render json: { error: "Query parameter is missing" }, status: :bad_request
    # end
    render json: { message: "index" }
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
end
