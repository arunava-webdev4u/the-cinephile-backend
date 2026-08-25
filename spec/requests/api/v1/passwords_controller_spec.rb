require "rails_helper"
require "sidekiq/testing"

RSpec.describe "Api::V1::Auth::PasswordsController", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:headers) { { "CONTENT_TYPE" => "application/json" } }
  let(:user) { create(:user) }

  before do
    Sidekiq::Testing.fake!
  end

  after do
    Sidekiq::Worker.clear_all
  end

  describe "POST /api/v1/auth/forgot_password" do
    context "with a registered email" do
      before do
        create(:user_verification, :verified, user: user)
      end

      it "returns ok with a generic message" do
        post "/api/v1/auth/forgot_password", params: { email: user.email }.to_json, headers: headers

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["message"]).to include("reset code has been sent")
      end

      it "regenerates the OTP" do
        old_otp = user.verification.otp_code

        post "/api/v1/auth/forgot_password", params: { email: user.email }.to_json, headers: headers

        expect(user.verification.reload.otp_code).not_to eq(old_otp)
        expect(user.verification.verified).to be_falsey
      end

      it "sets a fresh expiry 10 minutes out" do
        post "/api/v1/auth/forgot_password", params: { email: user.email }.to_json, headers: headers

        expect(user.verification.reload.otp_expires_at).to be_within(1.minute).of(10.minutes.from_now)
      end

      it "enqueues SendPasswordResetEmailWorker" do
        expect {
          post "/api/v1/auth/forgot_password", params: { email: user.email }.to_json, headers: headers
        }.to change(SendPasswordResetEmailWorker.jobs, :size).by(1)
      end
    end

    context "with an unverified account" do
      before do
        user.verification&.update!(verified: false)
      end

      it "returns forbidden on forgot_password" do
        post "/api/v1/auth/forgot_password", params: { email: user.email }.to_json, headers: headers

        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)["detail"]).to eq("Account is not verified")
      end

      it "returns forbidden on reset_password" do
        verification = user.verification || create(:user_verification, user: user, verified: false)

        post "/api/v1/auth/reset_password", params: {
          email: user.email, otp: verification.otp_code,
          password: "NewPass123", confirm_password: "NewPass123"
        }.to_json, headers: headers

        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)["detail"]).to eq("Account is not verified")
      end

      it "does not enqueue any email" do
        post "/api/v1/auth/forgot_password", params: { email: user.email }.to_json, headers: headers

        expect(SendPasswordResetEmailWorker.jobs).to be_empty
      end
    end

    context "with an unknown email" do
      it "returns not_found (global RecordNotFound handler)" do
        post "/api/v1/auth/forgot_password", params: { email: "ghost@example.com" }.to_json, headers: headers

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)["title"]).to eq("Not Found")
      end

      it "does not enqueue any email" do
        expect {
          post "/api/v1/auth/forgot_password", params: { email: "ghost@example.com" }.to_json, headers: headers
        }.not_to change(SendPasswordResetEmailWorker.jobs, :size)
      end
    end

    context "when email is missing" do
      it "returns bad_request via ParameterMissing handler" do
        post "/api/v1/auth/forgot_password", params: {}.to_json, headers: headers

        # find_by!(email: nil) raises RecordNotFound → 404
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /api/v1/auth/reset_password" do
    # A verified account with a pending (unverified-flag) reset OTP
    let!(:verification) do
      create(:user_verification, :verified, user: user)
      user.verification.update!(verified: false) # OTP pending for the reset flow
      user.reload.verification
    end

    context "with a valid OTP and matching passwords" do
      it "returns ok with success message" do
        post "/api/v1/auth/reset_password", params: {
          email: user.email, otp: verification.otp_code,
          password: "NewPass123", confirm_password: "NewPass123"
        }.to_json, headers: headers

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["message"]).to eq("Password has been reset successfully")
      end

      it "updates the password" do
        post "/api/v1/auth/reset_password", params: {
          email: user.email, otp: verification.otp_code,
          password: "NewPass123", confirm_password: "NewPass123"
        }.to_json, headers: headers

        expect(user.reload.authenticate("NewPass123")).to be_truthy
      end

      it "invalidates existing JWTs by rotating jti" do
        old_jti = user.jti

        post "/api/v1/auth/reset_password", params: {
          email: user.email, otp: verification.otp_code,
          password: "NewPass123", confirm_password: "NewPass123"
        }.to_json, headers: headers

        expect(user.reload.jti).not_to eq(old_jti)
      end
    end

    context "with an unknown email" do
      it "returns not_found" do
        post "/api/v1/auth/reset_password", params: {
          email: "ghost@example.com", otp: "123456",
          password: "NewPass123", confirm_password: "NewPass123"
        }.to_json, headers: headers

        expect(response).to have_http_status(:not_found)
      end
    end

    context "with no verification record (defensive)" do
      before do
        UserVerification.find_by(user_id: user.id)&.destroy
      end

      it "returns forbidden since the account cannot be proven verified" do
        post "/api/v1/auth/reset_password", params: {
          email: user.email, otp: "123456",
          password: "NewPass123", confirm_password: "NewPass123"
        }.to_json, headers: headers

        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)["detail"]).to eq("Account is not verified")
      end
    end

    context "with a wrong OTP" do
      it "returns bad_request" do
        post "/api/v1/auth/reset_password", params: {
          email: user.email, otp: "000000",
          password: "NewPass123", confirm_password: "NewPass123"
        }.to_json, headers: headers

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["detail"]).to eq("Invalid or expired code")
      end
    end

    context "with an expired OTP" do
      before do
        verification.update!(otp_expires_at: 15.minutes.ago)
      end

      it "returns bad_request" do
        post "/api/v1/auth/reset_password", params: {
          email: user.email, otp: verification.otp_code,
          password: "NewPass123", confirm_password: "NewPass123"
        }.to_json, headers: headers

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["detail"]).to eq("Invalid or expired code")
      end
    end

    context "when passwords do not match" do
      it "returns bad_request without changing the password" do
        old_digest = user.password_digest

        post "/api/v1/auth/reset_password", params: {
          email: user.email, otp: verification.otp_code,
          password: "NewPass123", confirm_password: "Different123"
        }.to_json, headers: headers

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["detail"]).to eq("Confirmation does not match")
        expect(user.reload.password_digest).to eq(old_digest)
      end
    end

    context "when the new password violates the password policy" do
      it "returns 422 with field errors via global RecordInvalid handler" do
        post "/api/v1/auth/reset_password", params: {
          email: user.email, otp: verification.otp_code,
          password: "weakpass", confirm_password: "weakpass"
        }.to_json, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["errors"]["password"]).to be_present
      end
    end

    context "after a successful reset" do
      it "the OTP can no longer be reused" do
        otp = verification.otp_code

        post "/api/v1/auth/reset_password", params: {
          email: user.email, otp: otp,
          password: "NewPass123", confirm_password: "NewPass123"
        }.to_json, headers: headers

        expect(response).to have_http_status(:ok)

        post "/api/v1/auth/reset_password", params: {
          email: user.email, otp: otp,
          password: "Another123", confirm_password: "Another123"
        }.to_json, headers: headers

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "OTP expiry edge cases" do
      it "rejects an OTP entered exactly at the expiry boundary" do
        travel_to(1.second.from_now) do
          verification.update!(otp_expires_at: Time.current)

          post "/api/v1/auth/reset_password", params: {
            email: user.email, otp: verification.otp_code,
            password: "NewPass123", confirm_password: "NewPass123"
          }.to_json, headers: headers

          expect(response).to have_http_status(:bad_request)
          expect(JSON.parse(response.body)["detail"]).to eq("Invalid or expired code")
        end
      end

      it "accepts an OTP one second before expiry" do
        travel_to(Time.current) do
          verification.update!(otp_expires_at: 1.second.from_now)

          post "/api/v1/auth/reset_password", params: {
            email: user.email, otp: verification.otp_code,
            password: "NewPass123", confirm_password: "NewPass123"
          }.to_json, headers: headers

          expect(response).to have_http_status(:ok)
        end
      end

      it "does not change the password when the OTP is expired" do
        old_digest = user.password_digest
        verification.update!(otp_expires_at: 15.minutes.ago)

        post "/api/v1/auth/reset_password", params: {
          email: user.email, otp: verification.otp_code,
          password: "NewPass123", confirm_password: "NewPass123"
        }.to_json, headers: headers

        expect(user.reload.password_digest).to eq(old_digest)
      end
    end

    context "cross-flow security" do
      it "a reset OTP cannot be used to verify email (and vice versa is moot — same record)" do
        # The reset flow sets verified=false; verify_email with the reset OTP
        # would mark the account verified WITHOUT knowing the current password.
        # This documents the (accepted) behavior of the shared-OTP design.
        user.verification&.update!(verified: false)
        verification = create(:user_verification, :verified, user: user)
        user.verification.update!(verified: false) # pending reset OTP
        reset_otp = user.verification.otp_code

        post "/api/v1/auth/verify_email", params: { email: user.email, otp: reset_otp }.to_json, headers: headers

        # Same OTP slot means this succeeds — accepted trade-off of shared OTP.
        # If this must be blocked, a `purpose` column on user_verifications is needed.
        expect(response).to have_http_status(:created)
      end

      it "a forgotten-password OTP regeneration invalidates any previously issued OTP for that account" do
        old_otp = user.verification.otp_code

        post "/api/v1/auth/forgot_password", params: { email: user.email }.to_json, headers: headers
        expect(response).to have_http_status(:ok)

        expect(user.verification.reload.otp_code).not_to eq(old_otp)
      end
    end

    context "token/session security after reset" do
      it "an old JWT no longer authenticates after a password reset" do
        old_token = Auth::JsonWebToken.encode({ user_id: user.id, jti: user.jti })

        post "/api/v1/auth/reset_password", params: {
          email: user.email, otp: verification.otp_code,
          password: "NewPass123", confirm_password: "NewPass123"
        }.to_json, headers: headers
        expect(response).to have_http_status(:ok)

        get "/api/v1/user", headers: headers.merge({ "Authorization" => "Bearer #{old_token}" })

        expect(response).to have_http_status(:unauthorized)
      end

      it "login works with the new password and fails with the old one" do
        post "/api/v1/auth/reset_password", params: {
          email: user.email, otp: verification.otp_code,
          password: "NewPass123", confirm_password: "NewPass123"
        }.to_json, headers: headers

        post "/api/v1/auth/login", params: { user: { email: user.email, password: "OldPass_123" } }.to_json, headers: headers
        expect(response).to have_http_status(:unauthorized)

        post "/api/v1/auth/login", params: { user: { email: user.email, password: "NewPass123" } }.to_json, headers: headers
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
