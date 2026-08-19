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

  describe "GET /api/v1/discover/popular" do
    let(:success_response) { { "results" => [ { "id" => 20, "title" => "Popular Movie" } ] } }

    context "when TMDB returns results" do
      before do
        allow(tmdb_service).to receive(:popular).with("movie").and_return(success_response)
      end

      it "calls TmdbService.popular with the required type and returns results" do
        get "/api/v1/discover/popular?type=movie", headers: headers

        expect(tmdb_service).to have_received(:popular).with("movie")
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq(success_response.to_json)
      end
    end

    context "when type is missing" do
      before do
        allow(tmdb_service).to receive(:popular).with(nil).and_raise(
          ArgumentError,
          "Type is required. Valid types: movie, person, tv"
        )
      end

      it "returns bad_request with a required-type error" do
        get "/api/v1/discover/popular", headers: headers

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["error"]).to include("Type is required")
      end
    end

    context "when TMDB returns no results" do
      before do
        allow(tmdb_service).to receive(:popular).with("movie").and_return([])
      end

      it "returns not_found with an error message" do
        get "/api/v1/discover/popular?type=movie", headers: headers

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)["error"]).to eq("No popular items found")
      end
    end

    context "when TMDB API fails" do
      before do
        allow(tmdb_service).to receive(:popular).with("movie").and_raise(TmdbService::TmdbError, "Service unavailable")
      end

      it "returns service unavailable" do
        get "/api/v1/discover/popular?type=movie", headers: headers

        expect(response).to have_http_status(:service_unavailable)
        expect(JSON.parse(response.body)).to include("error" => "External service unavailable")
      end
    end
  end

  describe "GET /api/v1/discover/trending" do
    let(:success_response) { { "results" => [ { "id" => 10, "title" => "Trending Movie" } ] } }

    context "when TMDB returns results" do
      before do
        allow(tmdb_service).to receive(:trending).with(nil, nil).and_return(success_response)
      end

      it "passes nil params through so the service can apply its default values" do
        get "/api/v1/discover/trending", headers: headers

        expect(tmdb_service).to have_received(:trending).with(nil, nil)
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq(success_response.to_json)
      end

      it "passes custom type and time_window params to the service" do
        allow(tmdb_service).to receive(:trending).with("movie", "day").and_return(success_response)

        get "/api/v1/discover/trending?type=movie&time_window=day", headers: headers

        expect(tmdb_service).to have_received(:trending).with("movie", "day")
        expect(response).to have_http_status(:ok)
      end
    end

    context "when TMDB returns no results" do
      before do
        allow(tmdb_service).to receive(:trending).with(nil, nil).and_return([])
      end

      it "returns not_found with an error message" do
        get "/api/v1/discover/trending", headers: headers

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)["error"]).to eq("No trending items found")
      end
    end

    context "when invalid params are sent" do
      before do
        allow(tmdb_service).to receive(:trending).with("invalid_type", "week").and_raise(ArgumentError, "Invalid type or time_window. Valid types: all, movie, person, tv. Valid time_windows: day, week")
      end

      it "returns bad_request with the validation error" do
        get "/api/v1/discover/trending?type=invalid_type&time_window=week", headers: headers

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["error"]).to include("Invalid type or time_window")
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

  describe "GET /api/v1/discover/available_today" do
    let(:success_response) { { "results" => [ { "id" => 30, "title" => "Available Today Movie" } ] } }

    context "when TMDB returns results" do
      before do
        allow(tmdb_service).to receive(:available_today).with("movie").and_return(success_response)
      end

      it "calls TmdbService.available_today with the required type and returns results" do
        get "/api/v1/discover/available_today?type=movie", headers: headers

        expect(tmdb_service).to have_received(:available_today).with("movie")
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq(success_response.to_json)
      end
    end

    context "when type is missing" do
      before do
        allow(tmdb_service).to receive(:available_today).with(nil).and_raise(
          ArgumentError,
          "Type is required. Valid types: movie, person, tv"
        )
      end

      it "returns bad_request with a required-type error" do
        get "/api/v1/discover/available_today", headers: headers

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["error"]).to include("Type is required")
      end
    end

    context "when TMDB returns no results" do
      before do
        allow(tmdb_service).to receive(:available_today).with("movie").and_return([])
      end

      it "returns not_found with an error message" do
        get "/api/v1/discover/available_today?type=movie", headers: headers

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)["error"]).to eq("No available today items found")
      end
    end

    context "when invalid params are sent" do
      before do
        allow(tmdb_service).to receive(:available_today).with("invalid_type").and_raise(
          ArgumentError,
          "Invalid type. Valid types: movie, person, tv"
        )
      end

      it "returns bad_request with the validation error" do
        get "/api/v1/discover/available_today?type=invalid_type", headers: headers

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["error"]).to include("Invalid type")
      end
    end

    context "when TMDB API fails" do
      before do
        allow(tmdb_service).to receive(:available_today).with("movie").and_raise(TmdbService::TmdbError, "Service unavailable")
      end

      it "returns service unavailable" do
        get "/api/v1/discover/available_today?type=movie", headers: headers

        expect(response).to have_http_status(:service_unavailable)
        expect(JSON.parse(response.body)).to include("error" => "External service unavailable")
      end
    end
  end
end
