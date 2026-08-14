module Cache
  module Keys
    def self.tmdb_entity(type, id)
      "tmdb:#{type}:#{id}"
    end

    def self.tmdb_search(type, query)
      "tmdb:search:#{type}:#{query.downcase.strip}"
    end

    def self.tmdb_trending(type, window = "day")
      "tmdb:trending:#{type}:#{window}"
    end

    def self.user_profile(user_id)
      "user:#{user_id}:profile"
    end

    def self.user_lists(user_id)
      "user:#{user_id}:lists"
    end
  end
end
