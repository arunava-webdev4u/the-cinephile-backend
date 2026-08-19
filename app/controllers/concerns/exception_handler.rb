# app/controllers/concerns/exception_handler.rb
module ExceptionHandler
    extend ActiveSupport::Concern

    included do
        # 1. Catch ANY error that inherits from Errors::ApplicationError
        rescue_from Errors::ApplicationError do |error|
            render json: {
                type:     "about:blank",
                title:    error.class.name.delete_suffix("Error").titleize,
                status:   error.status,
                detail:   error.message,
                instance: request.original_url
            }, status: error.status, content_type: "application/problem+json"
        end

        # 2. Catch TMDB errors from ANY controller (not just SearchController!)
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
    end
end
