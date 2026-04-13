REDIS_DEFAULTS = {
  connect_timeout: 5,
  read_timeout:    1,
  write_timeout:   1
}.freeze

# DB 0 — Cache
REDIS_CACHE = ConnectionPool.new(
  size:    ENV.fetch("RAILS_MAX_THREADS", 5).to_i,
  timeout: 5
) do
  Redis.new(REDIS_DEFAULTS.merge(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0")))
end

# DB 1 — Sidekiq
# Note: Sidekiq manages its own Redis connection pool internally via config/initializers/sidekiq.rb.
# Do NOT define a REDIS_SIDEKIQ pool here with short read_timeout — Sidekiq's BRPOP command
# blocks for several seconds waiting for jobs and requires a much longer read timeout.
