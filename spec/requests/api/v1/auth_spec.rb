require "rails_helper"
require "sidekiq/testing"

RSpec.describe "Api::V1::AuthController", type: :request do
    include ActiveSupport::Testing::TimeHelpers

    let(:headers) { { "CONTENT_TYPE" => "application/json" } }

    before do
        Sidekiq::Testing.fake!
    end

    after do
        Sidekiq::Worker.clear_all
    end

    describe "POST /api/v1/auth/login" do
        let!(:user) { create(:user, password: "Secret123", password_confirmation: "Secret123") }

        context "with valid credentials" do
            it "returns status ok" do
                post "/api/v1/auth/login", params: { user: { email: user.email, password: "Secret123" } }.to_json, headers: headers

                expect(response).to have_http_status(:ok)
            end

            it "returns a JWT token and user" do
                post "/api/v1/auth/login", params: { user: { email: user.email, password: "Secret123" } }.to_json, headers: headers

                expect(JSON.parse(response.body)).to include("token", "user")
            end
        end

        context "with invalid credentials" do
            context "when email is incorrect" do
                it "returns unauthorized status" do
                    post "/api/v1/auth/login", params: { user: { email: "abc@gmail.com", password: "Secret123" } }.to_json, headers: headers

                    expect(response).to have_http_status(:unauthorized)
                end

                it "returns proper error message" do
                    post "/api/v1/auth/login", params: { user: { email: "abc@gmail.com", password: "Secret123" } }.to_json, headers: headers

                    expect(JSON.parse(response.body)["detail"]).to eq("Authentication failed")
                end
            end

            context "when password is incorrect" do
                it "returns unauthorized status" do
                    post "/api/v1/auth/login", params: { user: { email: user.email, password: "abcd1234" } }.to_json, headers: headers

                    expect(response).to have_http_status(:unauthorized)
                end

                it "returns proper error message" do
                    post "/api/v1/auth/login", params: { user: { email: user.email, password: "abcd1234" } }.to_json, headers: headers

                    expect(JSON.parse(response.body)["detail"]).to eq("Authentication failed")
                end
            end

            context "when email & password both are incorrect" do
                it "returns unauthorized status" do
                    post "/api/v1/auth/login", params: { user: { email: "abc@gmail.com", password: "abcd1234" } }.to_json, headers: headers

                    expect(response).to have_http_status(:unauthorized)
                end

                it "returns proper error message" do
                    post "/api/v1/auth/login", params: { user: { email: "abc@gmail.com", password: "abcd1234" } }.to_json, headers: headers

                    expect(JSON.parse(response.body)["detail"]).to eq("Authentication failed")
                end
            end
        end
    end

    describe "POST /api/v1/auth/register" do
        register_params = {
            user: {
                email: "johndoe+#{SecureRandom.hex(4)}@gmail.com",
                password: "Password111",
                confirm_password: "Password111",
                first_name: "john",
                last_name: "doe",
                country: 356,
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
                expect(verification.verified_at).to be_nil
            end

            it "generates a 6-digit OTP code" do
                post "/api/v1/auth/register", params: register_params.to_json, headers: headers
                verification = User.find_by(email: register_params[:user][:email]).verification
                expect(verification.otp_code).to match(/^\d{6}$/)
            end

            it "enqueues SendVerificationEmailWorker" do
                expect {
                    post "/api/v1/auth/register", params: register_params.to_json, headers: headers
                }.to change { SendVerificationEmailWorker.jobs.size }.by(1)
            end

            it "fails if passwords do not match" do
                params = register_params.deep_dup
                params[:user][:confirm_password] = "2222"
                post "/api/v1/auth/register", params: params.to_json, headers: headers

                expect(response).to have_http_status(:bad_request)
                expect(JSON.parse(response.body)["detail"]).to eq("Confirmation does not match")
            end

            context "when user already exists" do
                let(:user) { create(:user) }

                context "and is verified" do
                    it "will not create a new record in user_verifications" do
                        create(:user_verification, :verified, user: user)

                        params = register_params.deep_dup
                        params[:user][:email] = user.email

                        post "/api/v1/auth/register", params: params.to_json, headers: headers

                        expect(response).to have_http_status(:bad_request)
                        expect(JSON.parse(response.body)["detail"]).to eq("Account already exists")
                    end

                  # it "should send email" do
                  # end
                end

                context "and is not verified" do
                    it "will update the record in user_verifications" do
                        create(:user_verification, :verified, user: user)
                        user.verification.update!(verified_at: nil) # simulate OTP pending for a reset flow

                        params = register_params.deep_dup
                        params[:user][:email] = user.email

                        post "/api/v1/auth/register", params: params.to_json, headers: headers

                        expect(response).to have_http_status(:created)
                        expect(JSON.parse(response.body)["message"]).to eq("Please verify your email with the OTP sent")
                    end

                    it "does not wipe verified_at (permanent email-verification marker)" do
                        create(:user_verification, :verified, user: user)
                        original_verified_at = user.verification.verified_at
                        expect(original_verified_at).to be_present

                        params = register_params.deep_dup
                        params[:user][:email] = user.email

                        post "/api/v1/auth/register", params: params.to_json, headers: headers

                        expect(user.reload.email_verified?).to be true
                        expect(user.verification.verified_at).to eq(original_verified_at)
                    end

                    it "should regenerate the OTP and otp_expires_at" do
                        verification = create(:user_verification, user: user)
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
                    password: "Password111",
                    confirm_password: "Password111",
                    first_name: "ben",
                    last_name: "ten",
                    country: 248,
                    date_of_birth: "2000-12-20"
                }
            }

            context "when required fields are missing" do
                it "fails when email is missing" do
                    post "/api/v1/auth/register", params: { user: register_params[:user].except(:email) }.to_json, headers: headers

                    expect(response).to have_http_status(:unprocessable_content)
                    expect(JSON.parse(response.body)["errors"]["email"]).to include("can't be blank")
                end

                it "fails when password is missing" do
                    post "/api/v1/auth/register", params: { user: register_params[:user].except(:password) }.to_json, headers: headers

                    expect(response).to have_http_status(:bad_request)
                    expect(JSON.parse(response.body)["detail"]).to eq("Confirmation does not match")
                end

                it "fails when first_name is missing" do
                    post "/api/v1/auth/register", params: { user: register_params[:user].except(:first_name) }.to_json, headers: headers

                    expect(response).to have_http_status(:unprocessable_content)
                    expect(JSON.parse(response.body)["errors"]["first_name"]).to include("can't be blank")
                end

                it "fails when last_name is missing" do
                    post "/api/v1/auth/register", params: { user: register_params[:user].except(:last_name) }.to_json, headers: headers

                    expect(response).to have_http_status(:unprocessable_content)
                    expect(JSON.parse(response.body)["errors"]["last_name"]).to include("can't be blank")
                end

                it "fails when country is missing" do
                    post "/api/v1/auth/register", params: { user: register_params[:user].except(:country) }.to_json, headers: headers

                    expect(response).to have_http_status(:unprocessable_content)
                    expect(JSON.parse(response.body)["errors"]["country"]).to include("can't be blank")
                end

                it "fails when date_of_birth is missing" do
                    post "/api/v1/auth/register", params: { user: register_params[:user].except(:date_of_birth) }.to_json, headers: headers

                    expect(response).to have_http_status(:unprocessable_content)
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

                        expect(response).to have_http_status(:unprocessable_content)
                        expect(JSON.parse(response.body)["errors"]["email"]).to include("is invalid")
                    end
                end

                it "fails when email is too long" do
                    email = "#{'a'*80} #{'5'*80} #{'k'*80} #{'x'*80}@example.com"
                    post "/api/v1/auth/register", params: { user: register_params[:user].merge(email: email) }.to_json, headers: headers

                    expect(response).to have_http_status(:unprocessable_content)
                    expect(JSON.parse(response.body)["errors"]["email"]).to include("is invalid")
                end
            end

            context "for password" do
                it "fails when password is too short" do
                    post "/api/v1/auth/register", params: { user: register_params[:user].merge(password: "Ab1x", confirm_password: "Ab1x") }.to_json, headers: headers

                    expect(response).to have_http_status(:unprocessable_content)
                    expect(JSON.parse(response.body)["errors"]["password"]).to include("is too short (minimum is 8 characters)")
                end

                it "fails when password has no uppercase letter" do
                    post "/api/v1/auth/register", params: { user: register_params[:user].merge(password: "lowercase123", confirm_password: "lowercase123") }.to_json, headers: headers

                    expect(response).to have_http_status(:unprocessable_content)
                    expect(JSON.parse(response.body)["errors"]["password"]).to include(
                        "must contain at least one uppercase letter"
                    )
                end

                it "fails when password has no lowercase letter" do
                    post "/api/v1/auth/register", params: { user: register_params[:user].merge(password: "UPPERCASE123", confirm_password: "UPPERCASE123") }.to_json, headers: headers

                    expect(response).to have_http_status(:unprocessable_content)
                    expect(JSON.parse(response.body)["errors"]["password"]).to include(
                        "must contain at least one lowercase letter"
                    )
                end

                it "fails when password has no digit" do
                    post "/api/v1/auth/register", params: { user: register_params[:user].merge(password: "NoDigitsHere", confirm_password: "NoDigitsHere") }.to_json, headers: headers

                    expect(response).to have_http_status(:unprocessable_content)
                    expect(JSON.parse(response.body)["errors"]["password"]).to include(
                        "must contain at least one digit"
                    )
                end

                it "succeeds with a strong password" do
                    params = register_params.deep_dup
                    params[:user][:password] = "Str0ng-P@ss"
                    params[:user][:confirm_password] = "Str0ng-P@ss"

                    expect {
                        post "/api/v1/auth/register", params: params.to_json, headers: headers
                    }.to change(User, :count).by(1)

                    expect(response).to have_http_status(:created)
                end
            end

            context "for first_name" do
                it "fails when not a string" do
                    post "/api/v1/auth/register", params: { user: register_params[:user].merge(first_name: "John123") }.to_json, headers: headers

                    expect(response).to have_http_status(:unprocessable_content)
                    expect(JSON.parse(response.body)["errors"]["first_name"]).to include("must contain only alphabets")
                end

                it "fails when too long" do
                    first_name = "asdkkfjhasdfjhaslkfhaslfhaslfhaslfjashflkashflasfhasljgsfjasgljasgflsfgasdlkfgasfjasgfjasgflasjfgaslfgaslfgsdljfg"
                    post "/api/v1/auth/register", params: { user: register_params[:user].merge(first_name: first_name) }.to_json, headers: headers

                    expect(response).to have_http_status(:unprocessable_content)
                    expect(JSON.parse(response.body)["errors"]["first_name"]).to include("is too long (maximum is 50 characters)")
                end

                it "fails when empty string" do
                    post "/api/v1/auth/register", params: { user: register_params[:user].merge(first_name: "") }.to_json, headers: headers

                    expect(response).to have_http_status(:unprocessable_content)
                    expect(JSON.parse(response.body)["errors"]["first_name"]).to include("is too short (minimum is 1 character)")
                end
            end

            context "for last_name" do
                it "fails when not a string" do
                    post "/api/v1/auth/register", params: { user: register_params[:user].merge(last_name: "John123") }.to_json, headers: headers

                    expect(response).to have_http_status(:unprocessable_content)
                    expect(JSON.parse(response.body)["errors"]["last_name"]).to include("must contain only alphabets")
                end

                it "fails when too long" do
                    last_name = "asdkkfjhasdfjhaslkfhaslfhaslfhaslfjashflkashflasfhasljgsfjasgljasgflsfgasdlkfgasfjasgfjasgflasjfgaslfgaslfgsdljfg"
                    post "/api/v1/auth/register", params: { user: register_params[:user].merge(last_name: last_name) }.to_json, headers: headers

                    expect(response).to have_http_status(:unprocessable_content)
                    expect(JSON.parse(response.body)["errors"]["last_name"]).to include("is too long (maximum is 50 characters)")
                end

                it "fails when empty string" do
                    post "/api/v1/auth/register", params: { user: register_params[:user].merge(last_name: "") }.to_json, headers: headers

                    expect(response).to have_http_status(:unprocessable_content)
                    expect(JSON.parse(response.body)["errors"]["last_name"]).to include("is too short (minimum is 1 character)")
                end
            end

            context "for country" do
                it "fails when country is not a string" do
                    post "/api/v1/auth/register", params: { user: register_params[:user].merge(country: "india") }.to_json, headers: headers

                    expect(response).to have_http_status(:unprocessable_content)
                    expect(JSON.parse(response.body)["errors"]["country"]).to include("is not a number")
                end

                it "fails when country is not a whole number" do
                    post "/api/v1/auth/register", params: { user: register_params[:user].merge(country: 3.14) }.to_json, headers: headers

                    expect(response).to have_http_status(:unprocessable_content)
                    expect(JSON.parse(response.body)["errors"]["country"]).to include("must be an integer")
                end
                it "fails when country is not a negetive number" do
                    post "/api/v1/auth/register", params: { user: register_params[:user].merge(country: -91) }.to_json, headers: headers

                    expect(response).to have_http_status(:unprocessable_content)
                    expect(JSON.parse(response.body)["errors"]["country"]).to include("must be greater than 0")
                end
            end

            context "for date_of_birth" do
                it "fails when invalid" do
                    post "/api/v1/auth/register", params: { user: register_params[:user].merge(date_of_birth: "abcd-xy-99") }.to_json, headers: headers

                    expect(response).to have_http_status(:unprocessable_content)
                end

                it "fails when date is in future" do
                    post "/api/v1/auth/register", params: { user: register_params[:user].merge(date_of_birth: Date.current + 1.day) }.to_json, headers: headers

                    expect(response).to have_http_status(:unprocessable_content)
                    expect(JSON.parse(response.body)["errors"]["date_of_birth"]).to include("can not be today or a future date")
                end

                it "fails when user is a ghost" do
                    post "/api/v1/auth/register", params: { user: register_params[:user].merge(date_of_birth: Date.current-120.years) }.to_json, headers: headers

                    expect(response).to have_http_status(:unprocessable_content)
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

                expect(response).to have_http_status(:bad_request)
                expect(JSON.parse(response.body)["detail"]).to include("Invalid or expired code")
            end

            it "rejects expired OTP" do
                verification = create(:user_verification, user: user, otp_expires_at: 15.minutes.ago)
                post "/api/v1/auth/verify_email", params: { email: user.email, otp: verification.otp_code }.to_json, headers: headers

                expect(response).to have_http_status(:bad_request)
                expect(JSON.parse(response.body)["detail"]).to include("Invalid or expired code")
            end

            it "rejects already verified emails" do
                verification.mark_verified!
                post "/api/v1/auth/verify_email", params: { email: user.email, otp: verification.otp_code }.to_json, headers: headers

                expect(response).to have_http_status(:bad_request)
                expect(JSON.parse(response.body)["detail"]).to include("Already verified")
            end

            it "sends welcome email in production environment" do
                allow(Rails.env).to receive(:production?).and_return(true)

                email_service = instance_double(SmtpGmailService)
                allow(SmtpGmailService).to receive(:new).and_return(email_service)
                expect(email_service).to receive(:send_welcome_email).with(user)

                post "/api/v1/auth/verify_email",
                    params: { email: user.email, otp: verification.otp_code }.to_json,
                    headers: headers

                expect(response).to have_http_status(:created)
                expect(JSON.parse(response.body)).to include("token", "user")
            end
        end

        context "with invalid parameters" do
            it "regects without email" do
                post "/api/v1/auth/verify_email", params: { otp: verification.otp_code }.to_json, headers: headers

                expect(response).to have_http_status(:not_found)
                expect(JSON.parse(response.body)["title"]).to eq("Not Found")
            end

            it "regects without otp" do
                post "/api/v1/auth/verify_email", params: { email: user.email }.to_json, headers: headers

                expect(response).to have_http_status(:bad_request)
                expect(JSON.parse(response.body)["detail"]).to include("Invalid or expired code")
            end

            it "rejects invalid email" do
                post "/api/v1/auth/verify_email", params: { email: "ax4!%5&g.@gmail.com", otp: verification.otp_code }.to_json, headers: headers

                expect(response).to have_http_status(:not_found)
                expect(JSON.parse(response.body)["title"]).to eq("Not Found")
            end

            it "rejects invalid otp" do
                post "/api/v1/auth/verify_email", params: { email: user.email, otp: "#2f6f3" }.to_json, headers: headers

                expect(response).to have_http_status(:bad_request)
                expect(JSON.parse(response.body)["detail"]).to include("Invalid or expired code")
            end
        end

        context "OTP expiry edge cases" do
            it "rejects an OTP entered exactly at the expiry boundary" do
                travel_to(1.second.from_now) do
                    verification.update!(otp_expires_at: Time.current)
                    post "/api/v1/auth/verify_email", params: { email: user.email, otp: verification.otp_code }.to_json, headers: headers

                    expect(response).to have_http_status(:bad_request)
                    expect(JSON.parse(response.body)["detail"]).to include("Invalid or expired code")
                end
            end

            it "accepts an OTP one second before expiry" do
                travel_to(Time.current) do
                    verification.update!(otp_expires_at: 1.second.from_now)
                    post "/api/v1/auth/verify_email", params: { email: user.email, otp: verification.otp_code }.to_json, headers: headers

                    expect(response).to have_http_status(:created)
                end
            end

            it "does not verify the account when the OTP is expired (state unchanged)" do
                verification.update!(otp_expires_at: 15.minutes.ago)

                post "/api/v1/auth/verify_email", params: { email: user.email, otp: verification.otp_code }.to_json, headers: headers

                expect(user.reload.email_verified?).to be false
            end
        end

        context "OTP reuse and cross-flow security" do
            it "rejects a second verification attempt with the same OTP after success" do
                post "/api/v1/auth/verify_email", params: { email: user.email, otp: verification.otp_code }.to_json, headers: headers
                expect(response).to have_http_status(:created)

                # mark_verified! sets verified=true; the guard rejects re-verification
                post "/api/v1/auth/verify_email", params: { email: user.email, otp: verification.otp_code }.to_json, headers: headers

                expect(response).to have_http_status(:bad_request)
                expect(JSON.parse(response.body)["detail"]).to include("Already verified")
            end

            it "invalidates the OTP issued before a newer one (old OTP becomes stale)" do
                old_otp = verification.otp_code

                # user re-registers → OTP regenerated
                register_params = {
                    user: {
                        email: user.email, password: "Regenerate1", confirm_password: "Regenerate1",
                        first_name: "John", last_name: "Doe", country: 356, date_of_birth: "2000-12-20"
                    }
                }
                post "/api/v1/auth/register", params: register_params.to_json, headers: headers
                expect(response).to have_http_status(:created)

                new_otp = user.verification.reload.otp_code
                expect(new_otp).not_to eq(old_otp)

                # old OTP must no longer work
                post "/api/v1/auth/verify_email", params: { email: user.email, otp: old_otp }.to_json, headers: headers

                expect(response).to have_http_status(:bad_request)
                expect(user.reload.email_verified?).to be false
            end

            it "verifying with the new OTP does not accept the old one either way around" do
                old_otp = verification.otp_code

                verification.regenerate!
                new_otp = verification.reload.otp_code

                post "/api/v1/auth/verify_email", params: { email: user.email, otp: new_otp }.to_json, headers: headers
                expect(response).to have_http_status(:created)

                # old OTP must not work even though the account is now verified
                post "/api/v1/auth/verify_email", params: { email: user.email, otp: old_otp }.to_json, headers: headers

                expect(response).to have_http_status(:bad_request)
            end

            it "does not leak whether the OTP was wrong vs expired in the message" do
                verification.update!(otp_expires_at: 15.minutes.ago)

                post "/api/v1/auth/verify_email", params: { email: user.email, otp: "000000" }.to_json, headers: headers

                expect(JSON.parse(response.body)["detail"]).to eq("Invalid or expired code")
            end
        end

        context "token behavior after verification" do
            it "returns a token that authenticates the now-verified user" do
                post "/api/v1/auth/verify_email", params: { email: user.email, otp: verification.otp_code }.to_json, headers: headers

                token = JSON.parse(response.body)["token"]
                get "/api/v1/user", headers: headers.merge({ "Authorization" => "Bearer #{token}" })

                expect(response).to have_http_status(:ok)
            end
        end
    end

    describe "DELETE /api/v1/auth/logout" do
        let(:user) { create(:user) }
        let(:token) { Auth::JsonWebToken.encode({ user_id: user.id, jti: user.jti }) }

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
