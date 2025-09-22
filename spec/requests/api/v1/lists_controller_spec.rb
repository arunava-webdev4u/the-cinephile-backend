require 'rails_helper'

RSpec.describe "Api::V1::ListsController", type: :request do
  let(:auth_token) { "sample-valid-token" }
  let(:user) { FactoryBot.create(:user) }
  let(:decoded_token) { { user_id: user.id, jti: user.jti } }
  let(:headers) { { "Authorization" => "Bearer #{auth_token}", "CONTENT_TYPE" => "application/json" } }

  before do
    allow(Auth::JsonWebToken).to receive(:decode).and_return(decoded_token)
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
  end

  context "for custom_lists" do
    before do
      FactoryBot.create(:custom_list, user_id: user.id)
      FactoryBot.create(:custom_list, user_id: user.id)
      FactoryBot.create(:custom_list, user_id: user.id)
    end

    describe "GET /api/v1/custom_list" do
      it "returns all four custom lists" do
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

      it "returns a nil custom list does not exist" do
        get "/api/v1/custom_list/99999", headers: headers

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to be_nil
      end
    end

    describe "POST /api/v1/custom_lists" do
      sample_custom_list = {
        list: {
          name: "New Custom List",
          description: "A description"
        }
      }

      context "with valid parameters" do
        context "without private field" do
          it "creates a new custom list" do
            post "/api/v1/custom_list", params: sample_custom_list.to_json, headers: headers

            expect(response).to have_http_status(:created)
            expect(JSON.parse(response.body)["user_id"]).to eq(user.id)
            expect(JSON.parse(response.body)["private"]).to eq(false)
            expect(JSON.parse(response.body)).to include("id", "user_id", "name", "description", "private", "created_at", "updated_at")
          end
        end

        # context "with private field" do
        #   sample_custom_list[:list].merge!({ private: true })

        #   it "creates a new custom list" do
        #     post "/api/v1/custom_list", params: sample_custom_list.to_json, headers: headers

        #     expect(response).to have_http_status(:created)
        #     expect(JSON.parse(response.body)["user_id"]).to eq(user.id)
        #     expect(JSON.parse(response.body)["private"]).to eq(true)
        #     expect(JSON.parse(response.body)).to include("id", "user_id", "name", "description", "private", "created_at", "updated_at")
        #   end
        # end
      end
    end

    describe "PUT /api/v1/custom_list/:id" do
      new_custom_list = {
        list: {
          name: "New Custom List",
          description: "This is edited description"
        }
      }

      let(:list) { FactoryBot.create(:custom_list, name: "Custom List", description: "New Description", user_id: user.id) }

      it "updates an existing custom list" do
        put "/api/v1/custom_list/#{list.id}", params: new_custom_list.to_json, headers: headers

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["name"]).to eq("New Custom List")
        expect(JSON.parse(response.body)["description"]).to eq("This is edited description")
      end
    end

    describe "DELETE /api/v1/custom_list/:id" do
      before do
        user.lists.destroy_all
      end

      it "deletes an existing custom list" do
        list1 = FactoryBot.create(:custom_list, name: "Custom List", description: "New Description", user_id: user.id)
        list2 = FactoryBot.create(:custom_list, name: "Custom List", description: "New Description", user_id: user.id)
        list3 = FactoryBot.create(:custom_list, name: "Custom List", description: "New Description", user_id: user.id)

        delete "/api/v1/custom_list/#{list1.id}", headers: headers

        expect(response).to have_http_status(:ok)
        expect(user.lists.count).to eq(2)
      end
    end
  end
end
