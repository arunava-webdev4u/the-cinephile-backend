module Cache
  module Cacheable
    def cached(key, ttl:, &block)
      Cache::Store.fetch(key, ttl: ttl, &block)
    end

    def bust(key)
      Cache::Store.delete(key)
    end
  end
end
