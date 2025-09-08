require "rails_helper"
require 'active_support/testing/time_helpers'

RSpec.describe Auth::JsonWebToken do
    include ActiveSupport::Testing::TimeHelpers
    let(:payload) { { id: 123, email: "user@gmail.com" } }

    describe 'constants' do
        it 'has the correct SECRET_KEY' do
            expect(described_class::SECRET_KEY).to eq(Rails.application.credentials.secret_key_base)
        end
    end

    describe ".encode" do
        let(:encoded_token) { described_class.encode(payload) }

        it "returns encoded JWT token as string" do
            expect(encoded_token).to be_a(String)
            expect(encoded_token.split(".").length).to eq(3)
        end

        it "it adds an expiration time to the payload" do
            decode = JWT.decode(encoded_token, described_class::SECRET_KEY, true, { algorithm: "HS256" }).first
            expect(decode["exp"]).to eq(described_class::EXPIRE_TIME)
        end
    end

    describe ".decode" do
        let(:encoded_token) { described_class.encode(payload) }

        context "with a valid token" do
            it "returns the payload" do
                decoded = described_class.decode(encoded_token)

                expect(decoded["id"]).to eq(payload[:id])
                expect(decoded[:id]).to eq(payload[:id])
                expect(decoded[:email]).to eq(payload[:email])
                expect(decoded["email"]).to eq(payload[:email])
            end
        end

        context 'with expired token' do
            let(:expired_token) do
                expired_payload = payload.merge(exp: 1.hour.ago.to_i)
                JWT.encode(expired_payload, described_class::SECRET_KEY, "HS256")
            end

            it 'returns nil' do
                result = described_class.decode(expired_token)
                expect(result).to be_nil
            end
        end

        context "with invalid token" do
            it 'returns nil for malformed token' do
                result = described_class.decode('invalid.token.here')
                expect(result).to be_nil
            end
        end
    end
end
