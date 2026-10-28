class Movies::ListSerializer
  def initialize(item, tmdb)
    @item = item
    @tmdb = tmdb
  end

  def as_json
    {
      id: @item.item_id,
      type: @item.item_type,
      title: @tmdb["title"],
      rating: @tmdb["vote_average"],
      year: release_year,
      poster: poster_url
    }
  end

  private

  def release_year
    date = @tmdb["release_date"]
    return if date.blank?

    Date.iso8601(date).year
  rescue Date::Error
    nil
  end

  def poster_url
    return nil unless @tmdb["poster_path"]
    "https://image.tmdb.org/t/p/w342#{@tmdb["poster_path"]}"
  end
end
