class TmdbService
  require "net/http"

  BASE_URL_V3 = "https://api.themoviedb.org/3"
  VALID_SEARCH_TYPES = %w[movie tv person].freeze

  # Custom exceptions for better error handling
  class TmdbError < StandardError; end
  class AuthenticationError < TmdbError; end

  def initialize
    @api_token = ENV["TMDB_API_READ_ACCESS_TOKEN"]
    raise AuthenticationError, "TMDB API token not found" if @api_token.blank?
  end

  # Search movie/tv
  def search_by_name(query, type)
    tmdb_request("search/#{type}?query=#{query}")
  end
  def search_by_id(id, type)
    tmdb_request("#{type}/#{id}")
  end

  # Trendings movie/tv
  def trending
    "trending"
  end

  # Collection ()
  # TV Seasons ()

  # Discover movie/tv
  def discover(type)
    # tmdb_request("discover/#{type}")
  end

  # Genre movie/tv
  def genre(type)
    # tmdb_request("genre/#{type}/list")
  end

  # Lists movies/tv/persons
  def lists(type, topic)
    # https://api.themoviedb.org/3/movie/now_playing
    # https://api.themoviedb.org/3/movie/popular
    # https://api.themoviedb.org/3/movie/top_rated
    # https://api.themoviedb.org/3/movie/upcoming

    # https://api.themoviedb.org/3/person/popular

    # https://api.themoviedb.org/3/tv/airing_today
    # https://api.themoviedb.org/3/tv/on_the_air
    # https://api.themoviedb.org/3/tv/popular
    # https://api.themoviedb.org/3/tv/top_rated
  end

  # Trending movie/tv
  def trending(type)
    # https://api.themoviedb.org/3/trending/all/{time_window}
    # https://api.themoviedb.org/3/trending/movie/{time_window}
    # https://api.themoviedb.org/3/trending/person/{time_window}
    # https://api.themoviedb.org/3/trending/tv/{time_window}
  end

  # Credits movie/tv
  def credits(type, id)
    # https://developer.themoviedb.org/reference/movie-credits
    # https://developer.themoviedb.org/reference/tv-series-credits
  end

  # Images movie/tv
  def images(type, id)
    # https://developer.themoviedb.org/reference/movie-images
    # https://developer.themoviedb.org/reference/tv-series-images
  end

  # External ids movie/tv
  def external_ids(type, id)
    # https://developer.themoviedb.org/reference/movie-external-ids
    # https://developer.themoviedb.org/reference/tv-series-external-ids
  end

  # Recommendations movie/tv
  def recommendations(type, id)
    # https://developer.themoviedb.org/reference/movie-recommendations
    # https://developer.themoviedb.org/reference/tv-series-recommendations
  end

  # Watch providers movie/tv
  def watch_providers(type, id)
    # https://developer.themoviedb.org/reference/movie-watch-providers
    # https://developer.themoviedb.org/reference/tv-series-watch-providers
  end

  # Videos movie/tv
  def videos(type, id)
    # https://developer.themoviedb.org/reference/movie-videos
    # https://developer.themoviedb.org/reference/tv-series-videos
  end

  private

  def tmdb_request(resource_path)
    url = URI("#{BASE_URL_V3}/#{resource_path}")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(url)
    request["accept"] = "application/json"
    request["Authorization"] = "Bearer " + @api_token

    response = http.request(request)
    JSON.parse(response.body)
  end
end
