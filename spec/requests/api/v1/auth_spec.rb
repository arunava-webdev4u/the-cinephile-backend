require "rails_helper"

RSpec.describe "Api::V1::AuthController", type: :request do
    let(:headers) { { "CONTENT_TYPE" => "application/json" } }
    
    describe "POST /api/v1/auth/login" do
        let!(:user) { create(:user, password: "secret123", password_confirmation: "secret123") }
        
        context "with valid credentials" do
            it "returns status ok" do
                post "/api/v1/auth/login", params: { user: { email: user.email, password: "secret123" } }.to_json, headers: headers
                expect(response).to have_http_status(:ok)
            end

            it "returns a JWT token and user" do
                post "/api/v1/auth/login", params: { user: { email: user.email, password: "secret123" } }.to_json, headers: headers
                expect(JSON.parse(response.body)).to include("token", "user")
            end
        end

        context "with invalid credentials" do
            context "when email is incorrect" do
                it "returns unauthorized status" do
                    post "/api/v1/auth/login", params: { user: { email: "abc@gmail.com", password: "secret123" } }.to_json, headers: headers
                    expect(response).to have_http_status(:unauthorized)
                end

                it "returns proper error message" do
                    post "/api/v1/auth/login", params: { user: { email: "abc@gmail.com", password: "secret123" } }.to_json, headers: headers
                    expect(JSON.parse(response.body)["error"]).to eq("email or password is incorrect")
                end
            end

            context "when password is incorrect" do
                it "returns unauthorized status" do
                    post "/api/v1/auth/login", params: { user: { email: user.email, password: "abcd1234" } }.to_json, headers: headers
                    expect(response).to have_http_status(:unauthorized)
                end

                it "returns proper error message" do
                    post "/api/v1/auth/login", params: { user: { email: user.email, password: "abcd1234" } }.to_json, headers: headers
                    expect(JSON.parse(response.body)["error"]).to eq("email or password is incorrect")
                end
            end

            context "when email & password both are incorrect" do
                it "returns unauthorized status" do
                    post "/api/v1/auth/login", params: { user: { email: "abc@gmail.com", password: "abcd1234" } }.to_json, headers: headers
                    expect(response).to have_http_status(:unauthorized)
                end

                it "returns proper error message" do
                    post "/api/v1/auth/login", params: { user: { email: "abc@gmail.com", password: "abcd1234" } }.to_json, headers: headers
                    expect(JSON.parse(response.body)["error"]).to eq("email or password is incorrect")
                end
            end
            
        end
    end

    describe "POST /api/v1/auth/register" do
        register_params = {
            user: {
                email: "johndoe@gmail.com",
                password: "1111",
                confirm_password: "1111",
                first_name: "john",
                last_name: "doe",
                country: 7,
                date_of_birth: "2000-12-20"
            }
        }

        context "with valid parameters" do
            it "creates a new user and returns created status" do
                post "/api/v1/auth/register", params: register_params.to_json, headers: headers
                expect(response).to have_http_status(:created)
            end
            
            it "creates a new user and returns token and user details" do
                post "/api/v1/auth/register", params: register_params.to_json, headers: headers
                expect(JSON.parse(response.body)).to include("message")
                expect(JSON.parse(response.body)["message"]).to eq("Please verify your email with the OTP sent")
            end

            it "fails if passwords do not match" do
                register_params.dig(:user, :confirm_password).replace("2222")
                post "/api/v1/auth/register", params: register_params.to_json, headers: headers
                expect(response).to have_http_status(:unprocessable_entity)
                expect(JSON.parse(response.body)["error"]).to eq("passwords don't match")
            end
        end

        context "with invalid parameters" do
            
        end
    end

    describe "POST /api/v1/auth/verify_email" do
        context "with valid parameters" do
        #     it "verifies email with valid OTP" do
        #     end
    
            # it "rejects expired OTP" do
            # end
            
            # it "rejects already verified emails" do
            # end
        end

        context "with invalid parameters" do
            # it "rejects invalid OTP" do
            # end
        end
    end

    describe "DELETE /api/v1/auth/logout" do
        let(:user) { create(:user) }
        let(:token) { JsonWebToken.encode({ user_id: user.id, jti: user.jti }) }
        
        it "logs out the user with proper response" do
            delete "/api/v1/auth/logout", headers: headers.merge({ "Authorization" => "Bearer #{token}" })
            expect(response).to have_http_status(:ok)
            expect(JSON.parse(response.body)["message"]).to eq("logged out")
        end

        it "invalidates the user's jti" do
            old_jti = user.jti
            delete "/api/v1/auth/logout", headers: headers.merge({ "Authorization" => "Bearer #{token}" })
            user.reload
            expect(user.jti).not_to eq(old_jti)
        end

        it "rejects logout if no token is provided" do
            delete "/api/v1/auth/logout", headers: headers
            expect(response).to have_http_status(:unauthorized)
        end
    end
end
