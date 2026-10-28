require "rails_helper"

RSpec.describe TvShows::ListSerializer do
  let(:item) do
    instance_double(ListItem, item_id: 123, item_type: "tv_show")
  end

  let(:tmdb_data) do
    {
      "name" => "The Example Show",
      "overview" => "A television series.",
      "vote_average" => 7.6,
      "first_air_date" => "2019-01-11",
      "poster_path" => "/example-poster.jpg"
    }
  end

  subject(:serialized) { described_class.new(item, tmdb_data).as_json }

  describe "#as_json" do
    it "maps TV show and TMDB data into the list response shape" do
      expect(serialized).to eq({
        id: 123,
        type: "tv_show",
        title: "The Example Show",
        rating: 7.6,
        year: 2019,
        poster: "https://image.tmdb.org/t/p/w342/example-poster.jpg"
      })
    end

    it "returns nil poster when TMDB has no poster path" do
      tmdb_data["poster_path"] = nil

      expect(serialized[:poster]).to be_nil
    end

    it "returns nil year when first_air_date is missing or invalid" do
      tmdb_data["first_air_date"] = "invalid"

      expect(serialized[:year]).to be_nil
    end
  end
end
