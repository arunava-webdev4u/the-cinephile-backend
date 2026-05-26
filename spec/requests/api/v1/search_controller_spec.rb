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
      it "should not call TmdbService" do
        get "/api/v1/search/name?type=#{}&query=#{query}", headers: headers

        expect(tmdb_service).not_to have_received(:search_by_name)
      end

      it "returns bad request with error message" do
        get "/api/v1/search/name?type=#{}&query=#{query}", headers: headers

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["error"]).to eq("Type parameter is required")
      end
    end

    context "when type parameter is missing" do
      it "should not call TmdbService" do
        get "/api/v1/search/name?query=#{query}", headers: headers

        expect(tmdb_service).not_to have_received(:search_by_name)
      end

      it "returns bad request with error message" do
        get "/api/v1/search/name?query=#{query}", headers: headers

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["error"]).to eq("Type parameter is required")
      end
    end

    context "when query parameter is blank" do
      it "should not call TmdbService" do
        get "/api/v1/search/name?type=#{type}&query=#{}", headers: headers

        expect(tmdb_service).not_to have_received(:search_by_name)
      end

      it "returns bad request with error message" do
        get "/api/v1/search/name?type=#{type}&query=#{}", headers: headers

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["error"]).to eq("Either query or tmdb_id parameter is not present")
      end
    end

    context "when query parameter is missing" do
      it "should not call TmdbService" do
        get "/api/v1/search/name?type=#{type}", headers: headers

        expect(tmdb_service).not_to have_received(:search_by_name)
      end

      it "returns bad request with error message" do
        get "/api/v1/search/name?type=#{type}", headers: headers

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["error"]).to eq("Either query or tmdb_id parameter is not present")
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
      it "should not call TmdbService" do
        get "/api/v1/search/id?type=#{}&tmdb_id=#{tmdb_id}", headers: headers

        expect(tmdb_service).not_to have_received(:search_by_id)
      end

      it "returns bad request with error message" do
        get "/api/v1/search/id?type=#{}&tmdb_id=#{tmdb_id}", headers: headers

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["error"]).to eq("Type parameter is required")
      end
    end

    context "when type parameter is missing" do
      it "should not call TmdbService" do
        get "/api/v1/search/id?tmdb_id=#{tmdb_id}", headers: headers

        expect(tmdb_service).not_to have_received(:search_by_id)
      end

      it "returns bad request with error message" do
        get "/api/v1/search/id?tmdb_id=#{tmdb_id}", headers: headers

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["error"]).to eq("Type parameter is required")
      end
    end

    context "when tmdb_id parameter is missing" do
      it "should not call TmdbService" do
        get "/api/v1/search/id?type=#{type}&tmdb_id=#{}", headers: headers

        expect(tmdb_service).not_to have_received(:search_by_id)
      end

      it "returns bad request with error message" do
        get "/api/v1/search/id?type=#{type}&tmdb_id=#{}", headers: headers

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["error"]).to eq("Either query or tmdb_id parameter is not present")
      end
    end

    context "when tmdb_id parameter is blank" do
      it "should not call TmdbService" do
        get "/api/v1/search/id?type=#{type}", headers: headers

        expect(tmdb_service).not_to have_received(:search_by_id)
      end

      it "returns bad request with error message" do
        get "/api/v1/search/id?type=#{type}", headers: headers

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["error"]).to eq("Either query or tmdb_id parameter is not present")
      end
    end

        context "with an invalid type parameter" do
      let(:invalid_type) { "album" }
      let(:tmdb_error_response) { { "success" => false, "status_code" => 34, "status_message" => "The resource you requested could not be found." } }

      before do
        allow(tmdb_service).to receive(:search_by_id).with(tmdb_id, invalid_type).and_return(tmdb_error_response)
      end

      it "calls TmdbService with the invalid type" do
        get "/api/v1/search/id?type=#{invalid_type}&tmdb_id=#{tmdb_id}", headers: headers

        expect(tmdb_service).to have_received(:search_by_id).with(tmdb_id, invalid_type)
      end

      it "returns the TMDB error response" do
        get "/api/v1/search/id?type=#{invalid_type}&tmdb_id=#{tmdb_id}", headers: headers

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq(tmdb_error_response)
      end
    end

    context "when TMDB API fails" do
      before do
        allow(tmdb_service).to receive(:search_by_id).and_raise(TmdbService::TmdbError, "Service unavailable")
      end

      it "returns service unavailable" do
        get "/api/v1/search/id?type=#{type}&tmdb_id=#{tmdb_id}", headers: headers

        expect(response).to have_http_status(:service_unavailable)
        expect(JSON.parse(response.body)).to include("error" => "External service unavailable")
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
        expect(JSON.parse(response.body)).to include("error" => "External service unavailable")
      end
    end
  end
end
