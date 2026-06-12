require 'rails_helper'

RSpec.describe "Api::V1::ListItemsController", type: :request do
  let(:auth_token) { "sample-valid-token" }
  let(:user) { FactoryBot.create(:user) }
  let(:other_user) { FactoryBot.create(:user) }
  let(:decoded_token) { { user_id: user.id, jti: user.jti } }
  let(:headers) { { "Authorization" => "Bearer #{auth_token}", "CONTENT_TYPE" => "application/json" } }
  let(:tmdb_service) { instance_double(TmdbService) }

  before do
    allow(Auth::JsonWebToken).to receive(:decode).and_return(decoded_token)
    allow(TmdbService).to receive(:new).and_return(tmdb_service)
  end

  describe "Authentication" do
    it "returns unauthorized if token is missing" do
      custom_list = FactoryBot.create(:custom_list, user_id: user.id)
      get "/api/v1/custom_list/#{custom_list.id}/list_items", headers: { "CONTENT_TYPE" => "application/json" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns unauthorized if token is invalid" do
      allow(Auth::JsonWebToken).to receive(:decode).and_return(nil)
      custom_list = FactoryBot.create(:custom_list, user_id: user.id)
      get "/api/v1/custom_list/#{custom_list.id}/list_items", headers: headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "for CustomList" do
    let(:custom_list) { FactoryBot.create(:custom_list, user_id: user.id) }

    describe "GET /api/v1/custom_list/:custom_list_id/list_items" do
      context "with list items" do
        before do
          FactoryBot.create(:list_item, list_id: custom_list.id, item_id: 550, item_type: "Movie")
          FactoryBot.create(:list_item, list_id: custom_list.id, item_id: 13, item_type: "Movie")
        end

        it "returns all list items for the custom list" do
          tmdb_response = [
            { id: 550, title: "Fight Club", poster_path: "/p64OWwaSF84jWNLDNnaYoYrn26w.jpg" },
            { id: 13, title: "Forrest Gump", poster_path: "/clnqTKzYo1v47Yx07pjnop75VTv.jpg" }
          ]
          allow(tmdb_service).to receive(:fetch_batch).and_return(tmdb_response)

          get "/api/v1/custom_list/#{custom_list.id}/list_items", headers: headers

          expect(response).to have_http_status(:ok)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response.length).to eq(2)
        end

        it "calls TmdbService with list items" do
          tmdb_response = [
            { id: 550, title: "Fight Club" },
            { id: 13, title: "Forrest Gump" }
          ]
          allow(tmdb_service).to receive(:fetch_batch).and_return(tmdb_response)

          get "/api/v1/custom_list/#{custom_list.id}/list_items", headers: headers

          expect(tmdb_service).to have_received(:fetch_batch)
        end

        it "returns items with TMDB data serialized" do
          tmdb_response = [
            { id: 550, title: "Fight Club", poster_path: "/p64OWwaSF84jWNLDNnaYoYrn26w.jpg" },
            { id: 13, title: "Forrest Gump", poster_path: "/clnqTKzYo1v47Yx07pjnop75VTv.jpg" }
          ]
          allow(tmdb_service).to receive(:fetch_batch).and_return(tmdb_response)

          get "/api/v1/custom_list/#{custom_list.id}/list_items", headers: headers

          parsed_response = JSON.parse(response.body)
          expect(parsed_response[0]).to include("id", "title")
          expect(parsed_response[1]).to include("id", "title")
        end
      end

      context "with no list items" do
        it "returns an empty array" do
          allow(tmdb_service).to receive(:fetch_batch).and_return([])

          get "/api/v1/custom_list/#{custom_list.id}/list_items", headers: headers

          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)).to eq([])
        end
      end

      context "when TMDB service returns some nil values" do
        before do
          FactoryBot.create(:list_item, list_id: custom_list.id, item_id: 550, item_type: "Movie")
          FactoryBot.create(:list_item, list_id: custom_list.id, item_id: 999999, item_type: "Movie")
        end

        it "filters out items where TMDB data is nil" do
          tmdb_response = [
            { id: 550, title: "Fight Club" },
            nil
          ]
          allow(tmdb_service).to receive(:fetch_batch).and_return(tmdb_response)

          get "/api/v1/custom_list/#{custom_list.id}/list_items", headers: headers

          parsed_response = JSON.parse(response.body)
          expect(parsed_response.length).to eq(1)
        end

        it "logs when TMDB data is missing (Bug #3: No Handling for Nil TMDB Data)" do
          tmdb_response = [
            { id: 550, title: "Fight Club" },
            nil
          ]
          allow(tmdb_service).to receive(:fetch_batch).and_return(tmdb_response)
          allow(Rails.logger).to receive(:warn)

          get "/api/v1/custom_list/#{custom_list.id}/list_items", headers: headers

          # Verify logger was called with warning about missing TMDB data
          expect(Rails.logger).to have_received(:warn).with(
            a_string_matching(/TMDB data missing for 1 of 2 list items/)
          )
        end
      end

      context "when list does not exist" do
        it "raises an error (ActionController::RoutingError or RecordNotFound)" do
          get "/api/v1/custom_list/99999/list_items", headers: headers
          expect(response).to have_http_status(:not_found)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response).to include("error")
          expect(parsed_response["error"]).to eq("List not found")
        end
      end
    end

    describe "POST /api/v1/custom_list/:custom_list_id/list_items" do
      let(:valid_params) { { list_item: { item_id: 550, item_type: "Movie" } } }
      let(:invalid_params) { { list_item: { item_id: nil, item_type: "Movie" } } }

      context "with valid parameters" do
        it "creates a new list item" do
          expect {
            post "/api/v1/custom_list/#{custom_list.id}/list_items", params: valid_params.to_json, headers: headers
          }.to change(ListItem, :count).by(1)

          expect(response).to have_http_status(:created)
        end

        it "returns the created list item" do
          post "/api/v1/custom_list/#{custom_list.id}/list_items", params: valid_params.to_json, headers: headers

          parsed_response = JSON.parse(response.body)
          expect(parsed_response["item_id"]).to eq(550)
          expect(parsed_response["item_type"]).to eq("movie")
          expect(parsed_response["list_id"]).to eq(custom_list.id)
        end
      end

      context "with invalid parameters" do
        it "returns unprocessable entity" do
          post "/api/v1/custom_list/#{custom_list.id}/list_items", params: invalid_params.to_json, headers: headers

          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "returns error details" do
          post "/api/v1/custom_list/#{custom_list.id}/list_items", params: invalid_params.to_json, headers: headers

          parsed_response = JSON.parse(response.body)
          expect(parsed_response).to include("errors")
        end
      end

      context "when list does not exist" do
        it "raises an error" do
          post "/api/v1/custom_list/99999/list_items", params: valid_params.to_json, headers: headers
          
          expect(response).to have_http_status(:not_found)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response).to include("error")
          expect(parsed_response["error"]).to eq("List not found")
        end
      end
    end

    describe "DELETE /api/v1/custom_list/:custom_list_id/list_items/:id" do
      let!(:list_item) { FactoryBot.create(:list_item, list_id: custom_list.id) }

      context "when list item exists" do
        it "deletes the list item" do
          expect {
            delete "/api/v1/custom_list/#{custom_list.id}/list_items/#{list_item.id}", headers: headers
          }.to change(ListItem, :count).by(-1)

          expect(response).to have_http_status(:ok)
        end

        it "returns success message" do
          delete "/api/v1/custom_list/#{custom_list.id}/list_items/#{list_item.id}", headers: headers

          parsed_response = JSON.parse(response.body)
          expect(parsed_response["message"]).to eq("Item removed from list")
        end
      end

      context "when list item does not exist" do
        it "receives not found" do
          delete "/api/v1/custom_list/#{custom_list.id}/list_items/99999", headers: headers
          expect(response).to have_http_status(:not_found)
          expect(JSON.parse(response.body)).to include("error")
          expect(JSON.parse(response.body)["error"]).to eq("List item not found")
        end
      end

      context "when list does not exist" do
        it "receives not found" do
          delete "/api/v1/custom_list/99999/list_items/#{list_item.id}", headers: headers
          expect(response).to have_http_status(:not_found)
          expect(JSON.parse(response.body)).to include("error")
          expect(JSON.parse(response.body)["error"]).to eq("List not found")
        end
      end
    end
  end

  context "for DefaultList" do
    let(:default_list) { user.lists.where(type: "DefaultList").first }

    describe "GET /api/v1/default_list/:default_list_id/list_items" do
      context "with list items" do
        before do
          FactoryBot.create(:list_item, list_id: default_list.id, item_id: 550, item_type: "Movie")
          FactoryBot.create(:list_item, list_id: default_list.id, item_id: 13, item_type: "Movie")
        end

        it "returns all list items for the default list" do
          tmdb_response = [
            { id: 550, title: "Fight Club" },
            { id: 13, title: "Forrest Gump" }
          ]
          allow(tmdb_service).to receive(:fetch_batch).and_return(tmdb_response)

          get "/api/v1/default_list/#{default_list.id}/list_items", headers: headers

          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body).length).to eq(2)
        end
      end

      context "with no list items" do
        it "returns an empty array" do
          allow(tmdb_service).to receive(:fetch_batch).and_return([])

          get "/api/v1/default_list/#{default_list.id}/list_items", headers: headers

          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)).to eq([])
        end
      end

      context "when list does not exist" do
        it "raises an error" do
          get "/api/v1/default_list/99999/list_items", headers: headers

          expect(response).to have_http_status(:not_found)
          parsed_response = JSON.parse(response.body)
          expect(parsed_response).to include("error")
          expect(parsed_response["error"]).to eq("List not found")
        end
      end
    end

    describe "POST /api/v1/default_list/:default_list_id/list_items" do
      let(:valid_params) { { list_item: { item_id: 550, item_type: "Movie" } } }

      context "with valid parameters" do
        it "creates a new list item" do
          expect {
            post "/api/v1/default_list/#{default_list.id}/list_items", params: valid_params.to_json, headers: headers
          }.to change(ListItem, :count).by(1)

          expect(response).to have_http_status(:created)
        end

        it "returns the created list item" do
          post "/api/v1/default_list/#{default_list.id}/list_items", params: valid_params.to_json, headers: headers

          parsed_response = JSON.parse(response.body)
          expect(parsed_response["item_id"]).to eq(550)
          expect(parsed_response["item_type"]).to eq("movie")
          expect(parsed_response["list_id"]).to eq(default_list.id)
        end
      end
    end

    describe "DELETE /api/v1/default_list/:default_list_id/list_items/:id" do
      let!(:list_item) { FactoryBot.create(:list_item, list_id: default_list.id) }

      context "when list item exists" do
        it "deletes the list item" do
          expect {
            delete "/api/v1/default_list/#{default_list.id}/list_items/#{list_item.id}", headers: headers
          }.to change(ListItem, :count).by(-1)

          expect(response).to have_http_status(:ok)
        end

        it "returns success message" do
          delete "/api/v1/default_list/#{default_list.id}/list_items/#{list_item.id}", headers: headers

          parsed_response = JSON.parse(response.body)
          expect(parsed_response["message"]).to eq("Item removed from list")
        end
      end
    end
  end

  context "Edge cases and potential authorization issues" do
    let(:custom_list) { FactoryBot.create(:custom_list, user_id: user.id) }
    let(:other_user_list) { FactoryBot.create(:custom_list, user_id: other_user.id) }

    describe "Authorization concerns" do
      it "allows current user to access their own list items" do
        FactoryBot.create(:list_item, list_id: custom_list.id, item_id: 550, item_type: "Movie")
        allow(tmdb_service).to receive(:fetch_batch).and_return([{ id: 550, title: "Fight Club" }])

        get "/api/v1/custom_list/#{custom_list.id}/list_items", headers: headers

        expect(response).to have_http_status(:ok)
      end

      # # BUG: This test will expose that there's NO authorization check on accessing another user's list
      it "currently allows accessing another user's list items (BUG - should be prevented)" do
        FactoryBot.create(:list_item, list_id: other_user_list.id, item_id: 550, item_type: "Movie")
        allow(tmdb_service).to receive(:fetch_batch).and_return([{ id: 550, title: "Fight Club" }])

        get "/api/v1/custom_list/#{other_user_list.id}/list_items", headers: headers

        # This should probably be 404 or 403, but currently returns 200
        expect(response).to have_http_status(:ok)
      end

      # # BUG: This test will expose that there's NO authorization check on creating list items in another user's list
      it "currently allows creating list items in another user's list (BUG - should be prevented)" do
        params = { list_item: { item_id: 550, item_type: "Movie" } }

        expect {
          post "/api/v1/custom_list/#{other_user_list.id}/list_items", params: params.to_json, headers: headers
        }.to change(ListItem, :count).by(1)

        # This should probably be 404 or 403, but currently returns 201
        expect(response).to have_http_status(:created)
      end

      # # BUG: This test will expose that there's NO authorization check on deleting another user's list items
      it "currently allows deleting another user's list items (BUG - should be prevented)" do
        list_item = FactoryBot.create(:list_item, list_id: other_user_list.id)

        expect {
          delete "/api/v1/custom_list/#{other_user_list.id}/list_items/#{list_item.id}", headers: headers
        }.to change(ListItem, :count).by(-1)

        # This should probably be 404 or 403, but currently returns 200
        expect(response).to have_http_status(:ok)
      end
    end

    describe "Clear route parameter naming (Bug #2)" do
      it "correctly extracts parameter based on type for CustomList" do
        # Bug #2 fix: set_list now extracts list_id based on type
        # For CustomList routes: uses params[:custom_list_id]
        # For DefaultList routes: uses params[:default_list_id]
        # This is clearer than using || operator
        custom_list = FactoryBot.create(:custom_list, user_id: user.id)
        list_item = FactoryBot.create(:list_item, list_id: custom_list.id)

        allow(tmdb_service).to receive(:fetch_batch).and_return([{ id: list_item.item_id }])

        # CustomList route uses custom_list_id parameter
        get "/api/v1/custom_list/#{custom_list.id}/list_items", headers: headers

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).not_to be_empty
      end

      it "correctly extracts parameter based on type for DefaultList" do
        # For DefaultList routes: correctly uses params[:default_list_id]
        default_list = user.lists.where(type: "DefaultList").first
        list_item = FactoryBot.create(:list_item, list_id: default_list.id)

        allow(tmdb_service).to receive(:fetch_batch).and_return([{ id: list_item.item_id }])

        # DefaultList route uses default_list_id parameter
        get "/api/v1/default_list/#{default_list.id}/list_items", headers: headers

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).not_to be_empty
      end
    end
  end
end
