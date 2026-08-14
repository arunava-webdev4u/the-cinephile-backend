module Cache
  class Store
    def self.fetch(key, ttl:, &block)
      Rails.cache.fetch(key, expires_in: ttl, &block)
    end

    def self.delete(key)
      Rails.cache.delete(key)
    end

    def self.delete_namespace(prefix)
      Rails.cache.delete_matched("#{prefix}:*")
    end

    def self.exist?(key)
      Rails.cache.exist?(key)
    end
  end
end
