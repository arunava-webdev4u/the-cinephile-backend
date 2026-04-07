module Movies
  class ListSerializer
    def initialize(item, tmdb)
      @item = item
      @tmdb = tmdb
    end

    def as_json
      {
        id: @item.item_id,
        type: @item.item_type,
        title: @tmdb["title"],
        description: @tmdb["overview"],
        poster: poster_url
      }
    end

    private

    def poster_url
      return nil unless @tmdb["poster_path"]
      "https://image.tmdb.org/t/p/w342#{@tmdb["poster_path"]}"
    end
  end
end