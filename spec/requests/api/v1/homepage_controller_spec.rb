require "rails_helper"

RSpec.describe "Api::V1::HomepageController", type: :request do
    describe "#index" do
        it "returns a welcome message with PostgreSQL version" do
            get "/"

            expect(response).to have_http_status(:ok)
            response_body = JSON.parse(response.body)
            expect(response_body["message"]).to start_with("Welcome to The Cinephile API. PG version:")
            expect(response_body["message"]).to match(/PG version: PostgreSQL \d+\.\d+/)
        end

        it "returns a welcome message even with an authentication header" do
            user = FactoryBot.create(:user)
            auth_token = "valid-token"
            allow(Auth::JsonWebToken).to receive(:decode).and_return({ user_id: user.id })
            headers = { "Authorization" => "Bearer #{auth_token}" }

            get "/", headers: headers

            expect(response).to have_http_status(:ok)
            response_body = JSON.parse(response.body)
            expect(response_body["message"]).to start_with("Welcome to The Cinephile API. PG version:")
        end
    end
end
