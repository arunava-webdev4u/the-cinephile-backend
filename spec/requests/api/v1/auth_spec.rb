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

          # it "fails if user already exists and is verified" do
          # end

          # it "creates a verification record for the user" do
          # end

          # it "sends a verification email to the user" do
          # end
        end

        context "with invalid parameters" do
            context "when required fields are missing" do
              # it "fails when email is missing" do
              # end

              # it "fails when password is missing" do
              # end

              # it "fails when first_name is missing" do
              # end

              # it "fails when last_name is missing" do
              # end

              # it "fails when country is missing" do
              # end

              # it "fails when date_of_birth is missing" do
              # end
            end

            context "for email" do
              # it "fails when email is invalid" do
              # end

              # it "fails when email is already taken by a verified user" do
              # end

              # it "creates a new user if email is taken by an unverified user" do
              # end
            end

            context "for password" do
            end

            context "for first_name" do
            end

            context "for last_name" do
            end

            context "for country" do
              # it "fails when country is invalid" do
              # end
            end

            context "for date_of_birth" do
              # it "fails when date_of_birth is invalid" do
              # end

              # it "fails when user is underage" do
              # end

              # it "fails when user is a ghost" do
              # end
            end
        end
    end

    describe "POST /api/v1/auth/verify_email" do
        let(:user) { create(:user) }
        let!(:verification) { create(:user_verification, user: user) }

        context "with valid parameters" do
            it "verifies email with valid OTP" do
                post "/api/v1/auth/verify_email", params: { email: user.email, otp: verification.otp_code }.to_json, headers: headers

                expect(response).to have_http_status(:created)
                expect(JSON.parse(response.body)).to include("token", "user")
            end

            it "rejects wrong OTP" do
                otp = (verification.otp_code.to_i + 1).to_s
                post "/api/v1/auth/verify_email", params: { email: user.email, otp: otp }.to_json, headers: headers

                expect(response).to have_http_status(:unprocessable_entity)
                expect(JSON.parse(response.body)["error"]).to include("Invalid or expired OTP")
            end

            it "rejects expired OTP" do
                verification = create(:user_verification, user: user, otp_expires_at: 15.minutes.ago)
                post "/api/v1/auth/verify_email", params: { email: user.email, otp: verification.otp_code }.to_json, headers: headers

                expect(response).to have_http_status(:unprocessable_entity)
                expect(JSON.parse(response.body)["error"]).to include("Invalid or expired OTP")
            end

            it "rejects already verified emails" do
                verification.update!(verified: true)
                post "/api/v1/auth/verify_email", params: { email: user.email, otp: verification.otp_code }.to_json, headers: headers

                expect(response).to have_http_status(:unprocessable_entity)
                expect(JSON.parse(response.body)["error"]).to include("Already verified")
            end

            context "with invalid parameters" do
                it "regects without email" do
                    post "/api/v1/auth/verify_email", params: { otp: verification.otp_code }.to_json, headers: headers

                    expect(response).to have_http_status(:not_found)
                    expect(JSON.parse(response.body)["error"]).to include("Account not found")
                end

                it "regects without otp" do
                    post "/api/v1/auth/verify_email", params: { email: user.email }.to_json, headers: headers

                    expect(response).to have_http_status(:unprocessable_entity)
                    expect(JSON.parse(response.body)["error"]).to include("Invalid or expired OTP")
                end

                it "rejects invalid email" do
                    post "/api/v1/auth/verify_email", params: { email: "ax4!%5&g.@gmail.com", otp: verification.otp_code }.to_json, headers: headers
                    expect(response).to have_http_status(:not_found)
                    expect(JSON.parse(response.body)["error"]).to include("Account not found")
                end

                it "rejects invalid otp" do
                    post "/api/v1/auth/verify_email", params: { email: user.email, otp: "#2f6f3" }.to_json, headers: headers
                    expect(response).to have_http_status(:unprocessable_entity)
                    expect(JSON.parse(response.body)["error"]).to include("Invalid or expired OTP")
                end
            end
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
