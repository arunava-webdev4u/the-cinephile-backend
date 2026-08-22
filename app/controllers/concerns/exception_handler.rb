# app/controllers/concerns/exception_handler.rb
module ExceptionHandler
  extend ActiveSupport::Concern

  included do
    # 1. TMDB catch-all (base TmdbError) — registered FIRST so it is matched LAST.
    #    Rails searches rescue_from handlers in reverse registration order, so
    #    more specific subclasses (ClientError, NotFoundError, etc.) below will
    #    win over this catch-all.
    rescue_from TmdbService::TmdbError do |error|
      Rails.logger.error "TMDB API error: #{error.message}"
      render json: {
        type:     "about:blank",
        title:    "Service Unavailable",
        status:   503,
        detail:   "External service unavailable: #{error.message}",
        instance: request.original_url
      }, status: 503, content_type: "application/problem+json"
    end

    # 2. Our custom application errors (BadRequestError, etc.)
    rescue_from Errors::ApplicationError do |error|
      render json: {
        type:     "about:blank",
        title:    error.class.name.delete_suffix("Error").titleize,
        status:   error.status,
        detail:   error.message,
        instance: request.original_url
      }, status: error.status, content_type: "application/problem+json"
    end

    # 2. TMDB client error (bad type, invalid params) → 400
    rescue_from TmdbService::ClientError do |error|
      render json: {
        type:     "about:blank",
        title:    "Bad Request",
        status:   400,
        detail:   error.message,
        instance: request.original_url
      }, status: 400, content_type: "application/problem+json"
    end

    # 3. TMDB not found (valid request, but no results) → 404
    rescue_from TmdbService::NotFoundError do |error|
      render json: {
        type:     "about:blank",
        title:    "Not Found",
        status:   404,
        detail:   error.message,
        instance: request.original_url
      }, status: 404, content_type: "application/problem+json"
    end

    # 5. TMDB rate limit → 429
    rescue_from TmdbService::RateLimitError do |error|
      render json: {
        type:     "about:blank",
        title:    "Too Many Requests",
        status:   429,
        detail:   error.message,
        instance: request.original_url
      }, status: 429, content_type: "application/problem+json"
    end

    # 6. TMDB server down / network issues → 503
    rescue_from TmdbService::ServerError do |error|
      Rails.logger.error "TMDB API error: #{error.message}"
      render json: {
        type:     "about:blank",
        title:    "Service Unavailable",
        status:   503,
        detail:   "External service unavailable: #{error.message}",
        instance: request.original_url
      }, status: 503, content_type: "application/problem+json"
    end
  end
end
