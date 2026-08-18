module Cache
  module Ttl
    TMDB_ENTITY   = 24.hours     # movies, shows, people — mostly static
    TMDB_SEARCH   = 1.hour       # search results shift less often
    TMDB_TRENDING = 24.hours     # more volatile
    TMDB_POPULAR  = 24.hours     # popular items
    USER_PROFILE  = 7.days        # user-generated, low churn
    USER_LISTS    = 5.minutes    # user-generated, higher churn
  end
end
