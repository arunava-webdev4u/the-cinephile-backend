# # app/serializers/movies/detail_serializer.rb

# module Movies
#   class DetailSerializer
#     def initialize(item, tmdb)
#       @item = item
#       @tmdb = tmdb
#     end

#     def as_json
#       {
#         item_id: @item.item_id,
#         item_type: @item.item_type,
#         tmdb_id: @tmdb["id"],
#         title: @tmdb["title"],
#         overview: @tmdb["overview"],
#         backdrop: backdrop_url,
#         poster: poster_url,
#         genres: genres,
#         runtime: @tmdb["runtime"],
#         rating: @tmdb["vote_average"],
#         director: director_name
#       }
#     end

#     private

#     def poster_url
#       return nil unless @tmdb["poster_path"]
#       "https://image.tmdb.org/t/p/w500#{@tmdb["poster_path"]}"
#     end

#     def backdrop_url
#       return nil unless @tmdb["backdrop_path"]
#       "https://image.tmdb.org/t/p/w780#{@tmdb["backdrop_path"]}"
#     end

#     def genres
#       @tmdb["genres"]&.map { |g| g["name"] } || []
#     end

#     def director_name
#       crew = @tmdb.dig("credits", "crew") || []
#       crew.find { |c| c["job"] == "Director" }&.dig("name")
#     end
#   end
# end
