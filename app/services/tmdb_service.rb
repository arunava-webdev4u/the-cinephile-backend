class TmdbService
    require "net/http"

    BASE_URL_V3 = "https://api.themoviedb.org/3"

    # https://developer.themoviedb.org/reference/person-popular-list  - TODO
    # http://image.tmdb.org/t/p/w200/{img}

    
    # type can be "movie", "tv_show", or "person"
    def search_by_name(query, type)
        return tmdb_request("search/#{type}?query=#{query}")
    end
    def search_by_id(id, type)
        return tmdb_request("#{type}/#{id}")
    end
    # Trendings
    def trending
        return "trending"
    end

    # Movie Lists
    # def popular
    #     url = URI("https://api.themoviedb.org/3/discover/movie?include_adult=false&include_video=false&language=en-US&page=1&sort_by=popularity.desc")
    #     tmdb_request(url)
    # end
    # def top_rated
    #     url = URI("https://api.themoviedb.org/3/discover/movie?include_adult=false&include_video=false&language=en-US&page=1&sort_by=vote_average.desc&without_genres=99,10755&vote_count.gte=200")
    #     tmdb_request(url)
    # end
    # def upcoming
    #     url = URI("https://api.themoviedb.org/3/discover/movie?include_adult=false&include_video=false&language=en-US&page=1&sort_by=popularity.desc&with_release_type=2|3&release_date.gte={min_date}&release_date.lte={max_date}")
    #     tmdb_request(url)
    # end
    # def now_playing
    #     url = URI("https://api.themoviedb.org/3/discover/movie?include_adult=false&include_video=false&language=en-US&page=1&sort_by=popularity.desc&with_release_type=2|3&release_date.gte={min_date}&release_date.lte={max_date}")
    #     tmdb_request(url)
    # end


    # TV Shows Lists
    # def airing_today
    #     url = URI("https://api.themoviedb.org/3/tv/airing_today?language=en-US&page=1")
    #     tmdb_request(url)
    # end
    # def on_the_air
    #     url = URI("https://api.themoviedb.org/3/tv/on_the_air?language=en-US&page=1")
    #     tmdb_request(url)
    # end
    # def popular
    #     url = URI("https://api.themoviedb.org/3/tv/popular?language=en-US&page=1")
    #     tmdb_request(url)
    # end
    # def top_rated
    #     url = URI("https://api.themoviedb.org/3/tv/top_rated?language=en-US&page=1")
    #     tmdb_request(url)
    # end


    private

    # def search_by_name(query, type)
    #     url = URI("https://api.themoviedb.org/3/search/#{type}?query=#{query}&include_adult=false&language=en-US&page=1")
    #     tmdb_request(url)
    # end

    def tmdb_request(resource_path)
        url = URI("#{BASE_URL_V3}/#{resource_path}")
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true

        request = Net::HTTP::Get.new(url)
        request["accept"] = "application/json"
        request["Authorization"] = "Bearer " + ENV["TMDB_API_READ_ACCESS_TOKEN"]

        response = http.request(request)
        JSON.parse(response.body)
    end
end
