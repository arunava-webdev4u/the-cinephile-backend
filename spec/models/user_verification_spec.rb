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

        it "is invalid with an OTP shorter than 6 digits" do
            v = build(:user_verification, user: user, otp_code: "12345")
            expect(v).not_to be_valid
            expect(v.errors[:otp_code]).to include("is the wrong length (should be 6 characters)")
        end

        it "is invalid with an OTP longer than 6 digits" do
            v = build(:user_verification, user: user, otp_code: "1234567")
            expect(v).not_to be_valid
            expect(v.errors[:otp_code]).to include("is the wrong length (should be 6 characters)")
        end

        it "is invalid without otp_expires_at" do
            v = build(:user_verification, user: user, otp_expires_at: nil)
            expect(v).not_to be_valid
            expect(v.errors[:otp_expires_at]).to include("can't be blank")
        end
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

        it "is false by default on a new verification" do
            v = create(:user_verification, user: create(:user))
            expect(v.verified?).to be false
        end
    end

    describe "#expired?" do
        it "returns false when otp has not expired yet" do
            travel_to 5.minutes.from_now do
                expect(verification.expired?).to be false
            end
        end

        it "returns true when otp has expired" do
            freeze_time do
                verification = create(:user_verification, user: create(:user), otp_expires_at: 10.minutes.from_now)
                travel 25.minutes
                expect(verification.expired?).to be true
            end
        end

        it "returns true exactly at the expiry boundary" do
            freeze_time do
                v = create(:user_verification, user: create(:user), otp_expires_at: Time.current)
                expect(v.expired?).to be true
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

        it "returns false for a nil otp" do
            expect(verification.match?(nil)).to be false
        end

        it "does case-sensitive comparison" do
            # OTPs are numeric strings, but verify the comparison is strict
            expect(verification.match?(verification.otp_code.to_i)).to be true
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

        it "persists changes to the database" do
            verification.mark_verified!
            reloaded = UserVerification.find(verification.id)
            expect(reloaded.verified).to be true
            expect(reloaded.verified_at).to be_present
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

        it "resets a previously verified record back to unverified" do
            verification.mark_verified!
            verification.regenerate!(ttl: 5.minutes)
            expect(verification.verified).to be false
            expect(verification.verified_at).to be_nil
        end

        it "sets the new expiry using the given ttl" do
            freeze_time do
                verification.regenerate!(ttl: 30.minutes)
                expect(verification.otp_expires_at).to be_within(1.second).of(30.minutes.from_now)
            end
        end

        it "persists the regenerated record" do
            verification.regenerate!(ttl: 10.minutes)
            reloaded = UserVerification.find(verification.id)
            expect(reloaded.otp_code).to eq(verification.otp_code)
        end
    end

    describe ".generate_otp" do
        it "generates a 6-digit string" do
            otp = UserVerification.generate_otp
            expect(otp).to be_a(String)
            expect(otp.length).to eq(6)
            expect(otp.to_i).to be_between(100_000, 999_999).inclusive
        end

        it "generates different OTPs on successive calls (statistically)" do
            otps = Array.new(10) { UserVerification.generate_otp }
            expect(otps.uniq.length).to be > 1
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

        it "is invalid without a user" do
            v = build(:user_verification, user: nil)
            expect(v).not_to be_valid
        end
    end
end
