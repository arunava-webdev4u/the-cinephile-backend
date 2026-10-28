require "rails_helper"

RSpec.describe Movies::ListSerializer do
  let(:item) do
    instance_double(ListItem, item_id: 550, item_type: "Movie")
  end

  let(:tmdb_data) do
    {
      "title" => "Fight Club",
      "overview" => "A ticking-time-bomb insomniac...",
      "vote_average" => 8.4,
      "release_date" => "1999-10-15",
      "poster_path" => "/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg"
    }
  end

  subject(:serialized) { described_class.new(item, tmdb_data).as_json }

  describe "#as_json" do
    it "maps item and tmdb data into the response shape" do
      expect(serialized).to eq({
        id: 550,
        type: "Movie",
        title: "Fight Club",
        rating: 8.4,
        year: 1999,
        poster: "https://image.tmdb.org/t/p/w342/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg"
      })
    end

    context "when tmdb has no poster_path" do
      let(:tmdb_data) { { "title" => "Fight Club", "poster_path" => nil } }

      it "returns nil poster" do
        expect(serialized[:poster]).to be_nil
      end
    end

    context "when tmdb data is missing keys entirely" do
      let(:tmdb_data) { {} }

      it "does not raise and returns nil metadata" do
        expect(serialized[:title]).to be_nil
        expect(serialized[:rating]).to be_nil
        expect(serialized[:year]).to be_nil
        expect(serialized[:poster]).to be_nil
      end
    end

    context "when release_date is invalid" do
      let(:tmdb_data) { { "release_date" => "not-a-date" } }

      it "returns a nil year" do
        expect(serialized[:year]).to be_nil
      end
    end

    it "does not leak internal attributes (e.g. list_id, user_id)" do
      expect(serialized.keys).to contain_exactly(:id, :type, :title, :rating, :year, :poster)
    end
  end
end
