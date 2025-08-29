require 'rails_helper'
require 'active_support/testing/time_helpers'

RSpec.describe UserVerification, type: :model do
    include ActiveSupport::Testing::TimeHelpers

    let(:user) { create(:user) }
    let(:verification) { create(:user_verification, user: user) }

    describe "validations" do
        it { should validate_presence_of(:otp_code) }
        it { should validate_length_of(:otp_code).is_equal_to(6) }
        it { should validate_presence_of(:otp_expires_at) }
    end

    describe "#verified?" do
        it "returns true if verified" do
            verification.update!(verified: true)
            expect(verification.verified?).to be true
        end

        it "returns false if not verified" do
            verification.update!(verified: false)
            expect(verification.verified?).to be false
        end
    end

    describe "#expired?" do
        it "returns true if otp_expires_at is in the past" do
            travel_to 5.minutes.from_now do
                expect(verification.expired?).to be false
            end
        end

        it "returns true if otp_expires_at is in the past" do
            freeze_time do
                verification = create(:user_verification, otp_expires_at: 10.minutes.from_now)
                travel 25.minutes
                expect(verification.expired?).to be true
            end
        end
        
    end

    describe "#match?" do
        it "returns true if otp matches" do
            expect(verification.match?(verification.otp_code)).to be true
        end

        it "returns false if otp does not match" do
            expect(verification.match?("000000")).to be false
        end
    end

    describe "#mark_verified!" do
        it "sets verified to true and records verified_at" do
            freeze_time do
                verification.mark_verified!
                expect(verification.verified).to be true
                expect(verification.verified_at).to eq(Time.current)
            end
        end
    end

    describe "#regenerate!" do
        it "regenerates otp_code and otp_expires_at" do
            freeze_time do
                old_otp = verification.otp_code
                otp_expires_at = verification.otp_expires_at
                travel 45.minutes
                verification.regenerate!(ttl: 10.minutes)
                expect(verification.otp_code).not_to eq(old_otp)
                expect(verification.otp_expires_at).not_to eq(otp_expires_at)
                expect(verification.verified).to be false
                expect(verification.verified_at).to be_nil
            end
        end
    end

    describe ".generate_otp" do
        it "generates a 6-digit string" do
            otp = UserVerification.generate_otp
            expect(otp).to be_a(String)
            expect(otp.length).to eq(6)
            expect(otp.to_i).to be_between(100_000, 999_999).inclusive
        end
    end

    describe "associations" do
        it 'belongs to user' do
            association = described_class.reflect_on_association(:user)
            expect(association.macro).to eq(:belongs_to)
        end

        it "is also destroyed when user is destroyed" do
            user = create(:user)
            create(:user_verification, user: user)

            expect { user.destroy }.to change { UserVerification.count }.by(-1)
        end
    end
end
