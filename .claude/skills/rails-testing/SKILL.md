---
name: rails-testing
category: Testing
applyTo:
  - patterns: ["**/*_spec.rb"]
  - patterns: ["spec/**"]
---

# RSpec Testing

## Structure
- `spec/models/` - Model tests (validations, associations)
- `spec/controllers/` - Controller/request tests (auth, authorization)
- `spec/services/` - Service tests (mock external APIs)
- `spec/workers/` - Worker tests (Sidekiq jobs)
- `spec/factories/` - FactoryBot test data

## Run Tests
```bash
bundle exec rspec           # All tests
bundle exec rspec spec/models/user_spec.rb  # Single file
COVERAGE=true bundle exec rspec             # With coverage
```

## Patterns

**Models**: Test validations, associations, methods
- `it { should validate_presence_of(:email) }`
- `it { should have_many(:lists) }`

**Controllers**: Test HTTP methods, auth, authorization, errors
- Test with/without auth token
- Test ownership authorization
- Verify status codes & error format

**Factories**: `create(:user)`, `build(:user)`, `create(:user, email: "x@y.com")`

**JWT Headers**: `{'Authorization' => "Bearer #{token}"}`

**Singular Resources**: Use `@current_user` (no ID param), test with token

**Key**: Mock external APIs, don't let DB errors bubble to API
