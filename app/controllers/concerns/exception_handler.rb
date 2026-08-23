# app/controllers/concerns/exception_handler.rb
module ExceptionHandler
  extend ActiveSupport::Concern

  included do
    # IMPORTANT: Rails matches rescue_from handlers in REVERSE registration order
    # (last registered wins). Handlers must therefore be registered from the MOST
    # GENERAL class to the MOST SPECIFIC one.

    def local_request?
      Rails.application.config.consider_all_requests_local
    end

    # 1. CATCH-ALL: Everything else (RuntimeError, NoMethodError, DB errors, etc.)
    rescue_from StandardError do |error|
      Rails.logger.error "#{error.class}: #{error.message}\n#{error.backtrace&.first(5)&.join("\n")}"

      render_problem(
        title:  "Internal Server Error",
        status: 500,
        detail: ErrorSanitizer.sanitize(error, safe: false, local_request: local_request?)
      )
    end

    # 2. TMDB base error → 503 (catch-all for ServerError and unexpected TMDB issues)
    rescue_from TmdbService::TmdbError do |error|
      Rails.logger.error "TMDB API error: #{error.message}"
      render_problem(
        title:  "Service Unavailable",
        status: 503,
        detail: "External service unavailable: #{ErrorSanitizer.sanitize(error, safe: true)}"
      )
    end

    # 3. Custom application errors (BadRequestError, etc.)
    rescue_from Errors::ApplicationError do |error|
      render_problem(
        title:  error.class.name.delete_suffix("Error").titleize,
        status: error.status,
        detail: ErrorSanitizer.sanitize(error, safe: true)
      )
    end

    # 4. TMDB client error (bad type, invalid params) → 400
    rescue_from TmdbService::ClientError do |error|
      render_problem(
        title:  "Bad Request",
        status: 400,
        detail: ErrorSanitizer.sanitize(error, safe: true)
      )
    end

    # 5. TMDB not found (valid request, no results) → 404
    rescue_from TmdbService::NotFoundError do |error|
      render_problem(
        title:  "Not Found",
        status: 404,
        detail: ErrorSanitizer.sanitize(error, safe: true)
      )
    end

    # 6. TMDB rate limit → 429
    rescue_from TmdbService::RateLimitError do |error|
      render_problem(
        title:  "Too Many Requests",
        status: 429,
        detail: ErrorSanitizer.sanitize(error, safe: true)
      )
    end

    # 7. TMDB server down → 503
    rescue_from TmdbService::ServerError do |error|
      Rails.logger.error "TMDB API error: #{error.message}"
      render_problem(
        title:  "Service Unavailable",
        status: 503,
        detail: "External service unavailable: #{ErrorSanitizer.sanitize(error, safe: true)}"
      )
    end

    # 8. Missing required param (e.g., params.require(:user) when :user is absent)
    rescue_from ActionController::ParameterMissing do |error|
      render_problem(
        title:  "Bad Request",
        status: 400,
        detail: "Missing required parameter: #{error.param}"
      )
    end

    # 9. Record not found (e.g., User.find_by! with no match)
    rescue_from ActiveRecord::RecordNotFound do |error|
      render_problem(
        title:  "Not Found",
        status: 404,
        detail: ErrorSanitizer.sanitize(error, safe: true)
      )
    end

    # 10. Validation failed (e.g., user.save! with invalid data)
    rescue_from ActiveRecord::RecordInvalid do |error|
      render_problem(
        title:  "Validation Failed",
        status: 422,
        detail: ErrorSanitizer.sanitize(error, safe: true),
        extensions: { errors: error.record.errors.to_hash }
      )
    end
  end

  private

  # Single place that shapes the RFC 9457 problem+json response.
  # When DTOs are introduced, this is the method to swap out.
  def render_problem(title:, status:, detail:, extensions: {})
    body = {
      type:     "about:blank",
      title:    title,
      status:   status,
      detail:   detail,
      instance: request.original_url
    }
    body.merge!(extensions) if extensions.present?

    render json: body, status: status, content_type: "application/problem+json"
  end
end
