---
name: setup
category: Development
applyTo:
  - patterns: [".env*"]
---

# Initial Setup

## Environment
Create `.env` with: `DATABASE_URL`, `REDIS_URL`, `JWT_SECRET_KEY`, `TMDB_API_KEY`, `GMAIL_USERNAME`, `GMAIL_PASSWORD`

## First Time
```bash
bundle install
bin/rails db:create db:migrate db:seed
bundle exec rspec  # Verify setup
```

## Tech Stack
- **Rails 7** API mode
- **PostgreSQL** database
- **Sidekiq** background jobs (Redis)
- **JWT** authentication
- **RSpec** testing
