# CLAUDE.md - The Cinephile Backend

Rails API backend for movie/TV show recommendations. PostgreSQL + JWT auth + Sidekiq jobs.

## Quick Start

| Task | Command |
|------|---------|
| Tests | `bundle exec rspec` |
| Dev server | `bin/rails s` |
| Migrations | `bin/rails db:migrate` |
| Security scan | `bin/brakeman` |
| Lint | `bin/rubocop` |
| Console | `bin/rails c` |

## Project Structure

```
app/
├── controllers/api/v1/      # API endpoint controllers
├── models/                  # Business logic and DB models
├── serializers/             # JSON response formatters
├── services/                # External integrations (TMDB, Email)
└── workers/                 # Sidekiq background jobs

speStructure

- `app/controllers/api/v1/` - RESTful endpoints
- `app/models/` - Business logic & DB
- `app/serializers/` - JSON responses
- `app/services/` - TMDB, Gmail integrations, ErrorSanitizer
- `app/workers/` - Sidekiq background jobs
- `spec/` - RSpec tests (mirrors app/)
- `lib/auth/` - JWT token logic
- `db/migrate/` - Schema migrations

## Architecture

- Versioned API requests at versioned endpoints
- RESTful resource actions (index, show, create, update, destroy)
- Authenticate with JWT tokens via `authenticable` concern
- Authorize user access to resources
- Return JSON responses via serializers

**Serializers** (`app/serializers`)
- Transform Ruby objects to JSON
- Control which attributes are included in responses
- Format nested associations
- Add computed properties

### Supporting Components

**Error Handling** (`app/controllers/concerns/exception_handler.rb` + `app/services/error_sanitizer.rb` + `app/controllers/errors/`)
- Global RFC 9457 problem+json error responses — see **docs/error_handling.md**
- Controllers raise exceptions; never render error hashes
- `rescue_from` order matters: general → specific (Rails matches in reverse)

**Services** (`app/services`)
- Encapsulate external integrations
- Examples:
  - `TmdbService` - Fetches movie/TV data from The Movie Database API
  - `SmtpGmailService` - Sends emails via Gmail SMTP
  - `ErrorSanitizer` - Masks unsafe error messages before exposing to clients
- Implement complex business logic not suited for models/controllers
- Return structured result objects

**Workers** (`app/workers`)
- Background job processing via Sidekiq
- Example: `SendVerificationEmailWorker` - Async email verification
- Inherit from `ApplicationJob`
- Use Redis as message broker

**Authentication** (`lib/auth/json_web_token.rb` + `app/controllers/concerns/authenticable.rb`)
- JWT-based stateless authentication
- Tokens include `user_id`, `email`, `jti` (for revocation)
- `jti` allows logout by invalidating token in database
- Decoded and verified in `Authenticable` concern

### Database

- **PostgreSQL** for persistence
- **Migrations** in `db/migrate/` for schema changes
- **Schema** defined in `db/schema.rb` (auto-generated)
- **Seeds** in `db/seeds.rb` for test data
- NOT NULL constraints and uniqueness constraints at DB level

### Testing

- **RSpec** for comprehensive testing
- **FactoryBot** for test data factories
- Test organization mirrors app structure
- Focus areas: models, controllers, services, workers
- Coverage expected for happy paths, edge cases, and error scenarios

## Database Schema

### Users Table
```ruby
create_table :users do |t|
  t.string :email, null: false
  t.string :password_digest
  t.string :jti  # JWT ID for logout support
  t.timestamps
end
```

### Lists & List Items
```Models

- `User` - email, password_digest, jti (JWT ID)
- `List` - parent container
- `CustomList` / `DefaultList` - list types
- `ListItem` - items in lists (item_id, item_type)
- `UserVerification` - email verification state
Signature: HMACSHA256(header.payload, secret_key)
```

### Login Flow
1. User POST to `/api/v1/login` with email + password
2. Server verifies credentials
3. Server generates JWT token with `user_id`, `email`, `jti`
4. Client stores token in secure location
5. Client includes token in `Authorization: Bearer <token>` header on subsequent requests

### Request Authentication
1. Server extracts token from `Authorization` header
2. Server decodes and verifies signature with secret key
3. Server checks `jti` not revoked in database
4. Server sets `@current_user` from decoded `user_id`
5. Controller uses `@current_user` for request context

### Logout
1. User calls DELETE `/api/v1/logout` with valid token
2. Server updates user's `jti` to new random value
3. Old token becomes invalid (jti doesn't match)
4. Client discards token

## API Response Formats

### Successful Responses

GET (single resource):
```json
{
  "id": 1,
  "name": "My List",
  "created_at": "2025-05-26T10:30:00Z"
}
```

GET (multiple resources):
```json
[
  { "id": 1, "name": "List 1" },
  { "id": 2, "name": "List 2" }
]
```

### Error Responses (RFC 9457 problem+json)

All errors are handled globally by `ExceptionHandler` and rendered as
problem+json. Controllers raise; they never render error hashes themselves.
See **docs/error_handling.md** for full details.

```json
{
  "type":     "about:blank",
  "title":    "Not Found",
  "status":   404,
  "detail":   "Couldn't find List with 'id'=999",
  "instance": "http://example.com/api/v1/custom_list/999"
}
```

| Status | Trigger |
|--------|---------|
| 400 | `Errors::BadRequestError`, `TmdbService::ClientError`, missing params |
| 401 | `Errors::UnauthorizedError` (e.g. failed login) |
| 403 | `Errors::ForbiddenError` (action not allowed) |
| 404 | `Errors::NotFoundError`, `ActiveRecord::RecordNotFound` |
| 422 | `ActiveRecord::RecordInvalid` (+ `errors` field extensions) |
| 429 | `TmdbService::RateLimitError` |
| 503 | TMDB down (`ServerError` / base `TmdbError`) |
| 500 | Anything else (masked as "Internal server error" in production) |

**Validation errors (422)** include field-level messages under `errors`.
Messages containing secrets/tokens/SQL are masked by `ErrorSanitizer`.

## JWT Authentication

### Rails Conventions
- Class names: `CamelCase` (e.g., `UserController`, `UserSerializer`)
- Method/variable names: `snake_case` (e.g., `current_user`, `find_or_create`)
- Database tables: `snake_case` plural (e.g., `users`, `list_items`)
- Files: `snake_case` (e.g., `user_controller.rb`)

### Validations
```ruby
class User < ApplicationRecord
  validates :email, presence: true, uniqueness: true
end
```

## RSpec Structure
```ruby
describe User do
  describe "validations" do
    it { should validate_presence_of(:email) }
  end

  describe "associations" do
    it { should have_many(:lists) }
  end

  describe "#method_name" do
    it "does something" do
      # Arrange
      user = create(:user)
      
      # Act
      result = user.method_name
      
      # Assert
      expect(result).to eq(expected_value)
    end
  end
end
```

### Controller Testing
```ruby
describe "GET /api/v1/lists" do
  context "with valid auth token" do
    it "returns user's lists" do
      user = create(:user)
      token = JsonWebToken.encode(user_id: user.id, jti: user.jti)
      
      get "/api/v1/lists", headers: { 'Authorization' => "Bearer #{token}" }
      
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to be_an(Array)
    end
  end

  context "without auth token" do
    it "returns 401 unauthorized" do
      get "/api/v1/lists"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
```

### Test Factories
```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { "secure_password_123" }
  end
end

# Usage in tests
user = create(:user)
user = create(:user, email: "custom@example.com")
```
nventions

**Naming**: CamelCase classes, snake_case methods/vars
**Validations**: Include presence, uniqueness, error messages
**Controllers**: RESTful actions, auth checks, authorization
**Single resources**: `resource :user` (not `resources`), use `@current_user`
- Use `byebug` gem: add `byebug` line in code
- Use `pry` gem: more interactive debugging
- Check request logs for HTTP details

## Resources

- [Rails Documentation](https://guides.rubyonrails.org/)
- [JWT Introduction](https://jwt.io/)
- [RSpec Documentation](https://rspec.info/)
- [TMDB API Docs](https://developer.themoviedb.org/3)
- [Sidekiq Documentation](https://sidekiq.org/)

Known Issues

1. **ListItem validations** - Missing validations cause DB errors (BUG_REPORT_LIST_ITEMS_CONTROLLER.md)
2. ~~**ListItemsController authorization** - No authorization checks~~ (fixed: scoped `find_by!` + `Errors::ForbiddenError`)
3. ~~**Error response inconsistency** - Some endpoints return different error formats~~ (fixed: global RFC 9457 problem+json via ExceptionHandler)

## Environment Setup

- `.env` required with: `DATABASE_URL`, `REDIS_URL`, `JWT_SECRET_KEY`, `TMDB_API_KEY`, `GMAIL_USERNAME`, `GMAIL_PASSWORD`
- See `.claude/SETUP.md` for initial setup checklist