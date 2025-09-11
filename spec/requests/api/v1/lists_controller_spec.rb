require 'rails_helper'

RSpec.describe "Api::V1::ListsController", type: :request do
  let(:auth_token) { "sample-valid-token" }
  let(:user) { FactoryBot.create(:user) }
  let(:decoded_token) { { user_id: user.id, jti: user.jti } }
  let(:headers) { { "Authorization" => "Bearer #{auth_token}" } }

  before do
    allow(Auth::JsonWebToken).to receive(:decode).and_return(decoded_token)
  end

  describe "GET /api/v1/default_list" do
    it "returns all four default lists" do
      get "/api/v1/default_list", headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).length).to eq(4)
    end
    it "returns default lists with necessary fields" do
      get "/api/v1/default_list", headers: headers

      JSON.parse(response.body).each do |x|
        expect(x).to include("id", "user_id", "name", "description", "private", "created_at", "updated_at")
        expect(x["user_id"]).to eq(user.id)
      end
    end
    it "default lists are always public" do
      get "/api/v1/default_list", headers: headers

      JSON.parse(response.body).each do |x|
        expect(x["private"]).to eq(false)
      end
    end
  end

  describe "GET /api/v1/default_list/:id" do
    it "returns a specific default list" do
      sample_default_lists = user.lists.where(type: "DefaultList")
      get "/api/v1/default_list/#{sample_default_lists.first.id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["id"]).to eq(sample_default_lists.first.id)
    end

    it "returns a nil default list does not exist" do
      get "/api/v1/default_list/99999", headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to be_nil
    end
  end
end
