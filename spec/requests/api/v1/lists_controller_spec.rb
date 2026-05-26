require 'rails_helper'

RSpec.describe "Api::V1::ListsController", type: :request do
  let(:auth_token) { "sample-valid-token" }
  let(:user) { FactoryBot.create(:user) }
  let(:other_user) { FactoryBot.create(:user) }
  let(:decoded_token) { { user_id: user.id, jti: user.jti } }
  let(:headers) { { "Authorization" => "Bearer #{auth_token}", "CONTENT_TYPE" => "application/json" } }

  before do
    allow(Auth::JsonWebToken).to receive(:decode).and_return(decoded_token)
  end

  describe "Authentication" do
    it "returns unauthorized if token is missing" do
      get "/api/v1/default_list", headers: { "CONTENT_TYPE" => "application/json" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns unauthorized if token is invalid" do
      allow(Auth::JsonWebToken).to receive(:decode).and_return(nil)
      get "/api/v1/default_list", headers: headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "for default_lists" do
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

    describe "Permissions - DefaultList is read-only" do
      let(:default_list) { user.lists.where(type: "DefaultList").first }

      it "blocks PUT /api/v1/default_list/:id" do
        put "/api/v1/default_list/#{default_list.id}",
            params: { list: { name: "Hacked Name" } }.to_json,
            headers: headers

        expect(response).to have_http_status(:not_found)
      end

      it "blocks PATCH /api/v1/default_list/:id" do
        patch "/api/v1/default_list/#{default_list.id}",
              params: { list: { name: "Hacked Name" } }.to_json,
              headers: headers

        expect(response).to have_http_status(:not_found)
      end

      it "blocks DELETE /api/v1/default_list/:id" do
        delete "/api/v1/default_list/#{default_list.id}", headers: headers

        expect(response).to have_http_status(:not_found)
      end

      it "blocks POST /api/v1/default_list" do
        post "/api/v1/default_list",
            params: { list: { name: "New List" } }.to_json,
            headers: headers

        expect(response).to have_http_status(:not_found)
      end

      it "does not mutate the default list on a PUT attempt" do
        original_name = default_list.name

        put "/api/v1/default_list/#{default_list.id}",
            params: { list: { name: "Mutated Name" } }.to_json,
            headers: headers

        expect(default_list.reload.name).to eq(original_name)
      end

      it "does not destroy the default list on a DELETE attempt" do
        expect {
          delete "/api/v1/default_list/#{default_list.id}", headers: headers
        }.not_to change(List, :count)
      end

    end
  end

  context "for custom_lists" do
    before do
      FactoryBot.create(:custom_list, user_id: user.id)
      FactoryBot.create(:custom_list, user_id: user.id)
      FactoryBot.create(:custom_list, user_id: user.id)
    end

    describe "GET /api/v1/custom_list" do
      it "returns all custom lists for the current user" do
        # Create a list for another user to ensure it's not returned
        FactoryBot.create(:custom_list, user_id: other_user.id)
        
        get "/api/v1/custom_list", headers: headers

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body).length).to eq(3)
      end

      it "returns custom lists with necessary fields" do
        get "/api/v1/custom_list", headers: headers

        JSON.parse(response.body).each do |x|
          expect(x).to include("id", "user_id", "name", "description", "private", "created_at", "updated_at")
          expect(x["user_id"]).to eq(user.id)
        end
      end
    end

    describe "GET /api/v1/custom_list/:id" do
      it "returns a specific custom list" do
        sample_custom_lists = user.lists.where(type: "CustomList")
        get "/api/v1/custom_list/#{sample_custom_lists.first.id}", headers: headers

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["id"]).to eq(sample_custom_lists.first.id)
      end

      it "returns nil if the list belongs to another user" do
        other_list = FactoryBot.create(:custom_list, user_id: other_user.id)
        get "/api/v1/custom_list/#{other_list.id}", headers: headers
        
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to be_nil
      end
    end

    describe "POST /api/v1/custom_list" do
      let(:valid_params) { { list: { name: "New Custom List", description: "A description" } } }
      let(:invalid_params) { { list: { name: "" } } }

      context "with valid parameters" do
        it "creates a new custom list" do
          post "/api/v1/custom_list", params: valid_params.to_json, headers: headers

          expect(response).to have_http_status(:created)
          expect(JSON.parse(response.body)["user_id"]).to eq(user.id)
          expect(JSON.parse(response.body)["private"]).to eq(false)
        end

        it "creates a private custom list" do
          post "/api/v1/custom_list", params: valid_params.deep_merge(list: { private: true }).to_json, headers: headers
          expect(JSON.parse(response.body)["private"]).to eq(true)
        end
      end

      context "with invalid parameters" do
        it "returns unprocessable entity" do
          post "/api/v1/custom_list", params: invalid_params.to_json, headers: headers
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)).to include("errors")
        end
      end
    end

    describe "PUT /api/v1/custom_list/:id" do
      let(:list) { FactoryBot.create(:custom_list, name: "Original Name", user_id: user.id) }
      let(:update_params) { { list: { name: "Updated Name" } } }

      it "updates an existing custom list" do
        put "/api/v1/custom_list/#{list.id}", params: update_params.to_json, headers: headers

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["name"]).to eq("Updated Name")
      end

      it "does not allow updating another user's list" do
        other_list = FactoryBot.create(:custom_list, user_id: other_user.id)
        put "/api/v1/custom_list/#{other_list.id}", params: update_params.to_json, headers: headers
        
        expect(response).to have_http_status(:not_found)
      end

      it "returns unprocessable entity on failure and uses correct error object" do
        # Trigger validation failure (assuming name can't be blank)
        put "/api/v1/custom_list/#{list.id}", params: { list: { name: "" } }.to_json, headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to include("errors")
      end

      it "does not route PATCH /api/v1/custom_list/:id" do
        list = FactoryBot.create(:custom_list, user_id: user.id)
        patch "/api/v1/custom_list/#{list.id}", headers: headers
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "DELETE /api/v1/custom_list/:id" do
      it "deletes an existing custom list" do
        list = FactoryBot.create(:custom_list, user_id: user.id)
        expect {
          delete "/api/v1/custom_list/#{list.id}", headers: headers
        }.to change(CustomList, :count).by(-1)
        
        expect(response).to have_http_status(:ok)
      end

      it "does not allow deleting another user's list" do
        other_list = FactoryBot.create(:custom_list, user_id: other_user.id)
        expect {
          delete "/api/v1/custom_list/#{other_list.id}", headers: headers
        }.not_to change(CustomList, :count)
        
        expect(response).to have_http_status(:not_found)
      end

      it "returns not found for non-existent list" do
        delete "/api/v1/custom_list/99999", headers: headers
        expect(response).to have_http_status(:not_found)
      end

      it "returns not found when trying to delete a default list" do
        default_list = user.lists.where(type: "DefaultList").first
        delete "/api/v1/custom_list/#{default_list.id}", headers: headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
