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
# REDIS_SIDEKIQ = ConnectionPool.new(size: 10, timeout: 5) do
#   Redis.new(redis_config.merge(url: ENV.fetch("REDIS_SIDEKIQ_URL", "redis://localhost:6379/1")))
# end
