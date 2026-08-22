require "rails_helper"

RSpec.describe "Api::V1::SearchController", type: :request do
  let(:tmdb_service) { instance_double(TmdbService) }
  let(:valid_search_types) { %w[movie tv person] }
  let(:user) { FactoryBot.create(:user) }
  let(:decoded_token) { { user_id: user.id, jti: user.jti } }
  let(:auth_token) { "sample-valid-token" }

  before do
    allow(TmdbService).to receive(:new).and_return(tmdb_service)
    stub_const("TmdbService::VALID_SEARCH_TYPES", valid_search_types)

    allow(Auth::JsonWebToken).to receive(:decode).and_return(decoded_token)
  end

  describe "GET /api/v1/search/name" do
    let(:query) { "titanic" }
    let(:type) { "movie" }
    let(:success_response) { [ { id: 458, name: "The Titanic" }, { id: 136, name: "Titans" } ] }
    let(:headers) { { "Authorization" => "Bearer #{auth_token}" } }

    before do
      allow(tmdb_service).to receive(:search_by_name).with(query, type).and_return(success_response)
    end

    context "with valid parameters" do
      it "should call TmdbService" do
        get "/api/v1/search/name?type=#{type}&query=#{query}", headers: headers

        expect(tmdb_service).to have_received(:search_by_name).with(query, type)
      end

      it "returns movies" do
        get "/api/v1/search/name?type=#{type}&query=#{query}", headers: headers

        expect(response.body).to eq(success_response.to_json)
      end
    end

    context "when type parameter is blank" do
      before do
        allow(tmdb_service).to receive(:search_by_name).with(query, "").and_raise(
          TmdbService::ClientError, "Invalid type ''. Valid types: movie, tv, person"
        )
      end

      it "returns bad request with error detail" do
        get "/api/v1/search/name?type=#{}&query=#{query}", headers: headers

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["detail"]).to include("Invalid type")
      end
    end

    context "when type parameter is missing" do
      before do
        allow(tmdb_service).to receive(:search_by_name).and_raise(
          TmdbService::ClientError, "Invalid type ''. Valid types: movie, tv, person"
        )
      end

      it "returns bad request with error detail" do
        get "/api/v1/search/name?query=#{query}", headers: headers

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["detail"]).to include("Invalid type")
      end
    end

    context "when query parameter is blank" do
      before do
        allow(tmdb_service).to receive(:search_by_name).with("", type).and_return({ "results" => [] })
      end

      it "calls TmdbService with empty query and returns results" do
        get "/api/v1/search/name?type=#{type}&query=#{}", headers: headers

        expect(tmdb_service).to have_received(:search_by_name).with("", type)
        expect(response).to have_http_status(:ok)
      end
    end

    context "when query parameter is missing" do
      before do
        allow(tmdb_service).to receive(:search_by_name).with(nil, type).and_return({ "results" => [] })
      end

      it "calls TmdbService with nil query and returns results" do
        get "/api/v1/search/name?type=#{type}", headers: headers

        expect(tmdb_service).to have_received(:search_by_name).with(nil, type)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /api/v1/search/id" do
    let(:tmdb_id) { "123" }
    let(:type) { "movie" }
    let(:success_response) { { id: 123, name: "movie" } }
    let(:headers) { { "Authorization" => "Bearer #{auth_token}" } }

    before do
      allow(tmdb_service).to receive(:search_by_id).with(tmdb_id, type).and_return(success_response)
    end

    context "with valid parameters" do
      it "should call TmdbService" do
        get "/api/v1/search/id?type=#{type}&tmdb_id=#{tmdb_id}", headers: headers

        expect(tmdb_service).to have_received(:search_by_id).with(tmdb_id, type)
      end

      it "returns movies" do
        get "/api/v1/search/id?type=#{type}&tmdb_id=#{tmdb_id}", headers: headers

        expect(response.body).to eq(success_response.to_json)
      end
    end

    context "when type parameter is blank" do
      before do
        allow(tmdb_service).to receive(:search_by_id).and_raise(
          TmdbService::ClientError, "Invalid type ''. Valid types: movie, tv, person"
        )
      end

      it "returns bad request with error detail" do
        get "/api/v1/search/id?type=#{}&tmdb_id=#{tmdb_id}", headers: headers

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["detail"]).to include("Invalid type")
      end
    end

    context "when type parameter is missing" do
      before do
        allow(tmdb_service).to receive(:search_by_id).and_raise(
          TmdbService::ClientError, "Invalid type ''. Valid types: movie, tv, person"
        )
      end

      it "returns bad request with error detail" do
        get "/api/v1/search/id?tmdb_id=#{tmdb_id}", headers: headers

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["detail"]).to include("Invalid type")
      end
    end

    context "when tmdb_id parameter is missing or blank" do
      before do
        allow(tmdb_service).to receive(:search_by_id).with("", type).and_raise(
          TmdbService::NotFoundError, "Resource not found"
        )
      end

      it "returns not_found with error detail" do
        get "/api/v1/search/id?type=#{type}&tmdb_id=#{}", headers: headers

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)["detail"]).to eq("Resource not found")
      end
    end

    context "with an invalid type parameter" do
      let(:invalid_type) { "album" }

      before do
        allow(tmdb_service).to receive(:search_by_id).with(tmdb_id, invalid_type).and_raise(
          TmdbService::ClientError, "Invalid type 'album'. Valid types: movie, tv, person"
        )
      end

      it "returns bad request with the validation error" do
        get "/api/v1/search/id?type=#{invalid_type}&tmdb_id=#{tmdb_id}", headers: headers

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["detail"]).to include("Invalid type 'album'")
      end
    end

    context "when TMDB API fails" do
      before do
        allow(tmdb_service).to receive(:search_by_id).and_raise(TmdbService::TmdbError, "Service unavailable")
      end

      it "returns service unavailable" do
        get "/api/v1/search/id?type=#{type}&tmdb_id=#{tmdb_id}", headers: headers

        expect(response).to have_http_status(:service_unavailable)
        expect(JSON.parse(response.body)["title"]).to eq("Service Unavailable")
        expect(JSON.parse(response.body)["detail"]).to include("External service unavailable")
      end
    end
  end

    describe "GET /api/v1/search/multi" do
    let(:query) { "avengers" }
    let(:success_response) { [ { id: 458, title: "The Avengers" }, { id: 136, title: "Avengers: Infinity War" } ] }
    let(:headers) { { "Authorization" => "Bearer #{auth_token}" } }

    before do
      allow(tmdb_service).to receive(:multi_search).and_return(success_response)
    end

    context "with valid query" do
      it "calls TmdbService with the query" do
        get "/api/v1/search/multi?query=#{query}", headers: headers
        expect(tmdb_service).to have_received(:multi_search).with(query)
      end

      it "returns the search results" do
        get "/api/v1/search/multi?query=#{query}", headers: headers
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq(success_response.to_json)
      end
    end

    context "when query parameter is missing" do
      before do
        allow(tmdb_service).to receive(:multi_search).with(nil).and_return({ "results" => [] })
      end

      it "calls TmdbService with nil" do
        get "/api/v1/search/multi", headers: headers
        expect(tmdb_service).to have_received(:multi_search).with(nil)
      end

      it "returns whatever the service sends back" do
        get "/api/v1/search/multi", headers: headers
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({ "results" => [] })
      end
    end

    context "when query parameter is blank" do
      before do
        allow(tmdb_service).to receive(:multi_search).with("").and_return({ "results" => [] })
      end

      it "calls TmdbService with empty string" do
        get "/api/v1/search/multi?query=", headers: headers
        expect(tmdb_service).to have_received(:multi_search).with("")
      end

      it "returns whatever the service sends back" do
        get "/api/v1/search/multi?query=", headers: headers
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({ "results" => [] })
      end
    end

    context "when TMDB API fails" do
      before do
        allow(tmdb_service).to receive(:multi_search).and_raise(TmdbService::TmdbError, "Service unavailable")
      end

      it "returns service unavailable" do
        get "/api/v1/search/multi?query=#{query}", headers: headers

        expect(response).to have_http_status(:service_unavailable)
        expect(JSON.parse(response.body)["title"]).to eq("Service Unavailable")
        expect(JSON.parse(response.body)["detail"]).to include("External service unavailable")
      end
    end
  end
end
