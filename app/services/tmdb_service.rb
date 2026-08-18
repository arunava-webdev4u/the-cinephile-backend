class TmdbService
  include Cache::Cacheable
  require "net/http"

  BASE_URL_V3 = "https://api.themoviedb.org/3"
  VALID_SEARCH_TYPES = %w[movie tv person].freeze

  # Custom exceptions for better error handling
  class TmdbError < StandardError; end
  class AuthenticationError < TmdbError; end
  class RateLimitError < TmdbError; end   # new
  class ServerError < TmdbError; end      # optional, for 5xx
  class NotFoundError < TmdbError; end    # optional, for 404

  def initialize
    @api_token = ENV["TMDB_API_READ_ACCESS_TOKEN"]
    raise AuthenticationError, "TMDB API token not found" if @api_token.blank?
  end

  # Search movie/tv
  def multi_search(query)
    return tmdb_request("search/multi?query=#{query}") if query.length < 3

    cached(Cache::Keys.tmdb_multi_search(query), ttl: Cache::Ttl::TMDB_SEARCH) do
      tmdb_request("search/multi?query=#{query}")
    end
  end

  def search_by_name(query, type)
    cached(Cache::Keys.tmdb_search(type, query), ttl: Cache::Ttl::TMDB_SEARCH) do
      tmdb_request("search/#{type}?query=#{query}")
    end
  end

  def search_by_id(id, type)
    cached(Cache::Keys.tmdb_entity(type, id), ttl: Cache::Ttl::TMDB_ENTITY) do
      tmdb_request("#{type}/#{id}")
    end
  end

  # Fetch multiple items in parallel for better performance
  def fetch_batch(items)
    threads = items.map do |item|
      Thread.new(item) do |i|
        begin
          search_by_id(i.item_id, i.item_type)
        rescue StandardError => e
          Rails.logger.error("[TmdbService] fetch_batch failed for #{i.item_type}/#{i.item_id}: #{e.message}")
          nil
        end
      end
    end

    threads.map(&:value)
  end

  # Trending movie/tv
  def trending(type, time_window = "week")
    cached(Cache::Keys.tmdb_trending(type, time_window), ttl: Cache::Ttl::TMDB_TRENDING) do
      tmdb_request("trending/#{type}/#{time_window}")
    end
    # https://api.themoviedb.org/3/trending/all/{time_window}
    # https://api.themoviedb.org/3/trending/movie/{time_window}
    # https://api.themoviedb.org/3/trending/person/{time_window}
    # https://api.themoviedb.org/3/trending/tv/{time_window}
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

    # Timeouts: 5s open, 10s read
    http.open_timeout = 5
    http.read_timeout = 10

    request = Net::HTTP::Get.new(url)
    request["accept"] = "application/json"
    request["Authorization"] = "Bearer #{@api_token}"

    response = http.request(request)

    # Check HTTP status codes
    case response.code.to_i
    when 200
      JSON.parse(response.body)
    when 401, 403
      raise AuthenticationError, "Invalid API key or unauthorized"
    when 404
      raise NotFoundError, "Resource not found"
    when 429
      raise RateLimitError, "Rate limit exceeded"
    when 500..599
      raise ServerError, "TMDB server error (#{response.code})"
    else
      raise TmdbError, "Unexpected response (#{response.code})"
    end
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    raise TmdbError, "Network timeout: #{e.message}"
  rescue JSON::ParserError => e
    raise TmdbError, "Invalid JSON response: #{e.message}"
  rescue SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET => e
    raise TmdbError, "Network error: #{e.message}"
  end
end
