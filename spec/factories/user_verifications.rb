FactoryBot.define do
  factory :user_verification do
    association :user
    # transient do
    #   custom_otp { nil }
    # end

    # otp_code { custom_otp || UserVerification.generate_otp }

    otp_code { UserVerification.generate_otp }
    otp_expires_at { 10.minutes.from_now }
    verified { false }
    verified_at { nil }
  end
end
