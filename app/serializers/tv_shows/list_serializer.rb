class TvShows::ListSerializer
  def initialize(item, tmdb)
    @item = item
    @tmdb = tmdb
  end

  def as_json
    {
      id: @item.item_id,
      type: @item.item_type,
      title: @tmdb["name"],
      rating: @tmdb["vote_average"],
      year: first_air_year,
      poster: poster_url
    }
  end

  private

  def first_air_year
    date = @tmdb["first_air_date"]
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
