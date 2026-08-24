# Global Error Handling

This document describes the centralized error handling architecture for the API.

## Overview

All errors are handled globally via the `ExceptionHandler` concern (included in
`Api::V1::ApplicationController`) and rendered as **RFC 9457 problem+json**
responses. Individual controllers no longer rescue or render their own errors —
they raise, and the global handler responds.

```
Controller raises → ExceptionHandler → ErrorSanitizer → render_problem → problem+json response
```

See `docs/diagrams/global_error_handling.drawio` for a visual diagram.

## Components

### 1. ExceptionHandler (`app/controllers/concerns/exception_handler.rb`)

Registers `rescue_from` handlers for every error family. Each handler calls
`render_problem`, the single place that shapes the RFC 9457 body:

```json
{
  "type":     "about:blank",
  "title":    "Bad Request",
  "status":   400,
  "detail":   "Invalid type 'album'. Valid types: movie, tv, person",
  "instance": "http://example.com/api/v1/search/id"
}
```

The HTTP status code is set both on the response line and inside the body
(mandated by RFC 9457). `ActiveRecord::RecordInvalid` additionally merges an
`errors` extension with field-level validation messages.

### 2. ErrorSanitizer (`app/services/error_sanitizer.rb`)

Centralizes the "is this message safe to expose?" policy:

- **Intentional errors** (`safe: true` — raised on purpose for client mistakes)
  pass through verbatim.
- **Unexpected errors** are masked as `"Internal server error"` unless the
  request is local (`consider_all_requests_local`).
- **Defense-in-depth**: any message matching unsafe patterns (`password`,
  `token`, `api_key`, SQL fragments, file paths) is masked even when marked safe.

Every handler routes its `detail` through the sanitizer. New handlers must do
the same.

### 3. Custom error classes (`app/controllers/errors/`)

All inherit from `Errors::ApplicationError`, which carries an HTTP `status`:

| Class | Status | Used for |
|---|---|---|
| `Errors::BadRequestError` | 400 | Invalid input, mismatched confirmations |
| `Errors::UnauthorizedError` | 401 | Failed authentication |
| `Errors::ForbiddenError` | 403 | Action not allowed for resource type |
| `Errors::NotFoundError` | 404 | Explicit not-found raises |

**Important**: files must declare the full namespace
(`class Errors::BadRequestError < Errors::ApplicationError`), not just
`class BadRequestError` — otherwise the constant won't resolve where referenced.

## Handler registration order — CRITICAL

Rails matches `rescue_from` handlers in **reverse registration order**
(last registered wins). Handlers must therefore be registered from the MOST
GENERAL class to the MOST SPECIFIC one:

1. `StandardError` (catch-all) — registered FIRST so it matches LAST
2. `TmdbService::TmdbError` (base TMDB class)
3. `Errors::ApplicationError`
4. `TmdbService::ClientError`
5. `TmdbService::NotFoundError`
6. `TmdbService::RateLimitError`
7. `TmdbService::ServerError`
8. `ActionController::ParameterMissing`
9. `ActiveRecord::RecordNotFound`
10. `ActiveRecord::RecordInvalid`

If a base class is registered *below* its subclasses, it shadows them entirely
(e.g., everything becoming 503 or 500). This has bitten us more than once —
see the precedence specs in `spec/controllers/concerns/exception_handler_spec.rb`.

## Error mapping by source

| Raised by | Handler | Response |
|---|---|---|
| `raise Errors::BadRequestError` | ApplicationError handler | 400 |
| `raise Errors::UnauthorizedError` | ApplicationError handler | 401 |
| `raise Errors::ForbiddenError` | ApplicationError handler | 403 |
| `raise Errors::NotFoundError` | ApplicationError handler | 404 |
| `find_by!` / `find` with no match | RecordNotFound handler | 404 |
| `create!` / `save!` / `update!` with invalid data | RecordInvalid handler | 422 + `errors` |
| `params.require(:x)` missing | ParameterMissing handler | 400 |
| Invalid TMDB type/params (`ClientError`) | ClientError handler | 400 |
| TMDB 404 (`NotFoundError`) | NotFoundError handler | 404 |
| TMDB rate limit (`RateLimitError`) | RateLimitError handler | 429 |
| TMDB down / network issues (`ServerError`, base `TmdbError`) | TmdbError handlers | 503 |
| Anything else | StandardError catch-all | 500 (masked in production) |

## Controller conventions

- Use bang methods (`find_by!`, `create!`, `update!`, `destroy!`) and let
  exceptions propagate — no manual `if saved? ... else render error` branches.
- Raise custom errors for business-rule failures:
  `raise Errors::UnauthorizedError.new("Authentication failed")`.
- Never render `{ error: ... }` hashes directly; that format is legacy.
- For authorization-by-scoping (`find_by!(id: ..., user_id: @current_user.id)`),
  a failed match surfaces as 404 — intentionally hiding that the resource exists.

## Testing

- Concern-level specs: `spec/controllers/concerns/exception_handler_spec.rb`
  (covers every handler, RFC 9457 shape, handler precedence, sanitizer integration).
- Sanitizer specs: `spec/services/error_sanitizer_spec.rb`.
- Request specs assert on `detail` / `title` keys of problem+json bodies, not
  the legacy `error` key.
