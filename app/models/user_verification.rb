class UserVerification < ApplicationRecord
    belongs_to :user

    validates :otp_code, presence: true, length: { is: 6 }
    validates :otp_expires_at, presence: true

    def expired?
        otp_expires_at <= Time.current
    end

    def match?(otp)
        ActiveSupport::SecurityUtils.secure_compare(otp_code, otp.to_s)
    end

    # Consumes the current OTP and stamps the permanent email-verification marker.
    def mark_verified!
        update!(verified_at: Time.current)
    end

    def regenerate!(ttl: 10.minutes)
        update!(
        otp_code: self.class.generate_otp,
        otp_expires_at: ttl.from_now
        )
    end

    def self.generate_otp
        rand(100_000..999_999).to_s
    end
end
