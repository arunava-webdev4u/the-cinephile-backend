require "rails_helper"

RSpec.describe "Api::V1::SearchController", type: :request do
  let(:tmdb_service) { instance_double(TmdbService) }
  let(:valid_search_types) { %w[movie tv person] }

  before do
    allow(TmdbService).to receive(:new).and_return(tmdb_service)
    stub_const("TmdbService::VALID_SEARCH_TYPES", valid_search_types)
  end

  describe "GET /api/v1/search/name" do
    context "with valid parameters" do

    end

    context "when type parameter is missing" do

    end

    context "when query parameter is missing" do

    end

    context "when query parameter is blank" do

    end

    context "when both required parameters are missing" do

    end
  end

  describe "GET /api/v1/search/id" do
    context "with valid parameters" do

    end

    context "when type parameter is missing" do

    end

    context "when tmdb_id parameter is missing" do

    end

    context "when tmdb_id parameter is blank" do

    end
  end

  describe "TmdbService initialization" do

  end

  describe "parameter filtering" do

  end
end
