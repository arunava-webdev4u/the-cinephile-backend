# frozen_string_literal: true

# Centralizes the "is this error message safe to expose to the client?" policy.
#
# Every rescue_from handler MUST route its `detail` through this sanitizer so
# that internal information (stack traces, SQL, file paths, third-party API
# internals) never leaks into API responses.
#
# Policy:
#   - Errors that are *intentional* (raised on purpose for a known client
#     mistake or state) are user-facing by definition → message is safe.
#   - Anything unexpected (StandardError catch-all) is masked unless the
#     request is local (development / consider_all_requests_local).
#   - Known-unsafe patterns are scrubbed even from "safe" messages as a
#     defense-in-depth measure.
module ErrorSanitizer
  # Messages containing any of these are never exposed verbatim.
  UNSAFE_PATTERNS = [
    /password/i,
    /secret/i,
    /token/i,
    /api[_\s-]?key/i,
    /credential/i,
    /\bSELECT\b.+\bFROM\b/i,   # SQL fragments
    /\/(app|lib|config|vendor)\//  # file paths
  ].freeze

  GENERIC_DETAIL = "Internal server error"

  class << self
    # Returns a detail string that is safe to include in an API response.
    #
    # @param error [Exception] the raised error
    # @param safe [Boolean] whether the error is intentional/user-facing.
    #   Intentional errors (BadRequestError, ClientError, NotFoundError...)
    #   pass through; unexpected errors are masked unless local.
    # @param local_request [Boolean] whether the request is considered local
    #   (Rails.application.config.consider_all_requests_local). Local requests
    #   see real messages even for unexpected errors, to aid debugging.
    def sanitize(error, safe:, local_request: false)
      # Unsafe-pattern check runs FIRST (defense-in-depth): even "safe"
      # intentional errors must never leak secrets, SQL, or file paths.
      return GENERIC_DETAIL if contains_unsafe?(error.message)

      return error.message if safe || local_request

      GENERIC_DETAIL
    end

    private

    def contains_unsafe?(message)
      UNSAFE_PATTERNS.any? { |pattern| pattern.match?(message) }
    end
  end
end
