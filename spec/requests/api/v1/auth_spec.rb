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

            it "should not return password or password_digest" do
                post "/api/v1/auth/register", params: register_params.to_json, headers: headers

                expect(JSON.parse(response.body)).not_to include("password", "password_digest")
            end

            it "creates a verification record for the user" do
                post "/api/v1/auth/register", params: register_params.to_json, headers: headers
                verification = User.find_by(email: register_params[:user][:email]).verification
                expect(verification).not_to be_nil
                expect(verification.verified).to be_falsey
            end

            it "fails if passwords do not match" do
                params = register_params.deep_dup
                params[:user][:confirm_password] = "2222"
                post "/api/v1/auth/register", params: params.to_json, headers: headers

                expect(response).to have_http_status(:unprocessable_entity)
                expect(JSON.parse(response.body)["error"]).to eq("passwords don't match")
            end

            context "when user already exists" do
                let(:user) { create(:user) }

                context "and is verified" do
                    it "will not create a new record in user_verifications" do
                        create(:user_verification, user: user, verified: true)

                        params = register_params.deep_dup
                        params[:user][:email] = user.email

                        post "/api/v1/auth/register", params: params.to_json, headers: headers

                        expect(response).to have_http_status(:unprocessable_entity)
                        expect(JSON.parse(response.body)["error"]).to eq("Account already exists and is verified")
                    end

                  # it "should send email" do
                  # end
                end

                context "and is not verified" do
                    it "will update the record in user_verifications" do
                        create(:user_verification, user: user, verified: false)

                        params = register_params.deep_dup
                        params[:user][:email] = user.email

                        post "/api/v1/auth/register", params: params.to_json, headers: headers

                        expect(response).to have_http_status(:created)
                        expect(JSON.parse(response.body)["message"]).to eq("Please verify your email with the OTP sent")
                    end

                    it "should regenerate the OTP and otp_expires_at" do
                        verification = create(:user_verification, user: user, verified: false)
                        old_otp = verification.otp_code
                        old_expiry = verification.otp_expires_at

                        params = register_params.deep_dup
                        params[:user][:email] = user.email

                        post "/api/v1/auth/register", params: params.to_json, headers: headers

                        verification.reload
                        expect(verification.otp_code).not_to eq(old_otp)
                        expect(verification.otp_expires_at).to be > old_expiry
                    end

                  # it "should send email" do
                  # end
                end
            end
        end

        context "with invalid parameters" do
            register_params = {
                user: {
                    email: "benten@gmail.com",
                    password: "1111",
                    confirm_password: "1111",
                    first_name: "ben",
                    last_name: "ten",
                    country: 7,
                    date_of_birth: "2000-12-20"
                }
            }

            context "when required fields are missing" do
                it "fails when email is missing" do
                    post "/api/v1/auth/register", params: { user: register_params[:user].except(:email) }.to_json, headers: headers

                    expect(response).to have_http_status(:unprocessable_entity)
                    expect(JSON.parse(response.body)["errors"]["email"]).to include("can't be blank")
                end

                it "fails when password is missing" do
                    post "/api/v1/auth/register", params: { user: register_params[:user].except(:password) }.to_json, headers: headers

                    expect(response).to have_http_status(:unprocessable_entity)
                    expect(JSON.parse(response.body)["error"]).to include("passwords don't match")
                end

                it "fails when first_name is missing" do
                    post "/api/v1/auth/register", params: { user: register_params[:user].except(:first_name) }.to_json, headers: headers

                    expect(response).to have_http_status(:unprocessable_entity)
                    expect(JSON.parse(response.body)["errors"]["first_name"]).to include("can't be blank")
                end

                it "fails when last_name is missing" do
                    post "/api/v1/auth/register", params: { user: register_params[:user].except(:last_name) }.to_json, headers: headers

                    expect(response).to have_http_status(:unprocessable_entity)
                    expect(JSON.parse(response.body)["errors"]["last_name"]).to include("can't be blank")
                end

                it "fails when country is missing" do
                    post "/api/v1/auth/register", params: { user: register_params[:user].except(:country) }.to_json, headers: headers

                    expect(response).to have_http_status(:unprocessable_entity)
                    expect(JSON.parse(response.body)["errors"]["country"]).to include("can't be blank")
                end

                it "fails when date_of_birth is missing" do
                    post "/api/v1/auth/register", params: { user: register_params[:user].except(:date_of_birth) }.to_json, headers: headers

                    expect(response).to have_http_status(:unprocessable_entity)
                    expect(JSON.parse(response.body)["errors"]["date_of_birth"]).to include("can't be blank")
                end
            end

            context "for email" do
                it "fails when email is in invalid" do
                    invalid_emails = [
                        'abc!%4&g.@gmail.com',
                        'abc.gmail.com',
                        'abc@',
                        'abc@gmail',
                        '@gmail.com',
                        'abc@@gmail.com',
                        'abc gmail@gmail.com',
                        'invalid-email'
                    ]
                    invalid_emails.each do |invalid_email|
                        post "/api/v1/auth/register", params: { user: register_params[:user].merge(email: invalid_email) }.to_json, headers: headers

                        expect(response).to have_http_status(:unprocessable_entity)
                        expect(JSON.parse(response.body)["errors"]["email"]).to include("is invalid")
                    end
                end

                it "fails when email is too long" do
                    email = "#{'a'*80} #{'5'*80} #{'k'*80} #{'x'*80}@example.com"
                    post "/api/v1/auth/register", params: { user: register_params[:user].merge(email: email) }.to_json, headers: headers

                    expect(response).to have_http_status(:unprocessable_entity)
                    expect(JSON.parse(response.body)["errors"]["email"]).to include("is invalid")
                end
            end

            context "for password" do
            end

            context "for first_name" do
            end

            context "for last_name" do
            end

            context "for country" do
                it "fails when country is not a string" do
                    post "/api/v1/auth/register", params: { user: register_params[:user].merge(country: "india") }.to_json, headers: headers

                    expect(response).to have_http_status(:unprocessable_entity)
                    expect(JSON.parse(response.body)["errors"]["country"]).to include("is not a number")
                end

                it "fails when country is not a whole number" do
                    post "/api/v1/auth/register", params: { user: register_params[:user].merge(country: 3.14) }.to_json, headers: headers

                    expect(response).to have_http_status(:unprocessable_entity)
                    expect(JSON.parse(response.body)["errors"]["country"]).to include("must be an integer")
                end
                it "fails when country is not a negetive number" do
                    post "/api/v1/auth/register", params: { user: register_params[:user].merge(country: -91) }.to_json, headers: headers

                    expect(response).to have_http_status(:unprocessable_entity)
                    expect(JSON.parse(response.body)["errors"]["country"]).to include("must be greater than 0")
                end
            end

            context "for date_of_birth" do
                it "fails when invalid" do
                    post "/api/v1/auth/register", params: { user: register_params[:user].merge(date_of_birth: "abcd-xy-99") }.to_json, headers: headers

                    expect(response).to have_http_status(:unprocessable_entity)
                end

                it "fails when date is in future" do
                    post "/api/v1/auth/register", params: { user: register_params[:user].merge(date_of_birth: Date.current + 1.day) }.to_json, headers: headers

                    expect(response).to have_http_status(:unprocessable_entity)
                    expect(JSON.parse(response.body)["errors"]["date_of_birth"]).to include("can not be today or a future date")
                end

                it "fails when user is a ghost" do
                    post "/api/v1/auth/register", params: { user: register_params[:user].merge(date_of_birth: Date.current-120.years) }.to_json, headers: headers

                    expect(response).to have_http_status(:unprocessable_entity)
                    expect(JSON.parse(response.body)["errors"]["date_of_birth"]).to include("are you kidding me? You are too old!")
                end
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
