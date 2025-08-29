require "rails_helper"

RSpec.describe "Api::V1::AuthController", type: :request do
    let(:headers) { { "CONTENT_TYPE" => "application/json" } }
    
    describe "POST /api/v1/auth/login" do
        let!(:user) { create(:user, password: "secret123", password_confirmation: "secret123") }
        
        context "with valid credentials" do
            it "returns a JWT token and user" do
                post "/api/v1/auth/login", params: { user: { email: user.email, password: "secret123" } }.to_json, headers: headers
                expect(response).to have_http_status(:ok)
                expect(JSON.parse(response.body)).to include("token", "user")
            end
        end

        context "without invalid credentials" do
            it "returns error" do
                post "/api/v1/auth/login", params: { user: { email: user.email, password: "abcd1234" } }.to_json, headers: headers
                expect(response).to have_http_status(:unauthorized)
                expect(JSON.parse(response.body)["error"]).to eq("email or password is incorrect")
            end
        end
    end

    describe "POST /api/v1/auth/register" do
    end

    describe "POST /api/v1/auth/verify_email" do
    end

    describe "DELETE /api/v1/auth/logout" do
    end
end
