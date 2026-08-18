require "rails_helper"

RSpec.describe "Api::V1::DiscoverController", type: :request do
  let(:tmdb_service) { instance_double(TmdbService) }
  let(:user) { FactoryBot.create(:user) }
  let(:decoded_token) { { user_id: user.id, jti: user.jti } }
  let(:auth_token) { "sample-valid-token" }

  before do
    allow(TmdbService).to receive(:new).and_return(tmdb_service)
    allow(Auth::JsonWebToken).to receive(:decode).and_return(decoded_token)
  end

  let(:headers) { { "Authorization" => "Bearer #{auth_token}" } }

  describe "GET /api/v1/discover/trending" do
    let(:success_response) { { "results" => [ { "id" => 10, "title" => "Trending Movie" } ] } }

    context "when TMDB returns results" do
      before do
        allow(tmdb_service).to receive(:trending).with("movie", "week").and_return(success_response)
      end

      it "calls TmdbService.trending and returns results" do
        get "/api/v1/discover/trending", headers: headers

        expect(tmdb_service).to have_received(:trending).with("movie", "week")
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq(success_response.to_json)
      end
    end

    context "when TMDB returns no results" do
      before do
        allow(tmdb_service).to receive(:trending).with("movie", "week").and_return([])
      end

      it "returns not_found with an error message" do
        get "/api/v1/discover/trending", headers: headers

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)["error"]).to eq("No trending movies found")
      end
    end

    context "when TMDB API fails" do
      before do
        allow(tmdb_service).to receive(:trending).and_raise(TmdbService::TmdbError, "Service unavailable")
      end

      it "returns service unavailable" do
        get "/api/v1/discover/trending", headers: headers

        expect(response).to have_http_status(:service_unavailable)
        expect(JSON.parse(response.body)).to include("error" => "External service unavailable")
      end
    end
  end
end
