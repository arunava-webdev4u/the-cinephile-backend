require "rails_helper"

RSpec.describe "Api::V1::HomepageController", type: :request do
    describe "#index" do
        context "without authentication" do
            it "returns unauthorized" do
                get "/"

                expect(response).to have_http_status(:ok)
                expect(JSON.parse(response.body)["message"]).to start_with("Welcome to The Cinephile API.")
            end
        end
    end
end
