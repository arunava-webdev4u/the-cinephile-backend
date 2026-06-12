require 'rails_helper'

RSpec.describe "Api::V1::MetadataController", type: :request do
  describe "GET /api/v1/metadata/countries" do
    it "returns a list of countries with their codes and common names" do
      get "/api/v1/metadata/countries"

      expect(response).to have_http_status(:ok)

      json_response = JSON.parse(response.body)
      expect(json_response).to be_an(Array)
      expect(json_response).not_to be_empty

      # Check a few specific countries
      expect(json_response).to include(
        { "code" => "840", "name" => "United States" },
        { "code" => "356", "name" => "India" },
        { "code" => "076", "name" => "Brazil" } # This needs to be 'Brazil', not 'Brasil'
      )

      # Check structure of first item
      first_country = json_response.first
      expect(first_country).to include("code", "name")
      expect(first_country["code"]).to be_a(String)
      expect(first_country["name"]).to be_a(String)
    end
  end
end
