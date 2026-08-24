class User < ApplicationRecord
    include Constants
    has_many :lists, dependent: :destroy
    has_one :verification, class_name: "UserVerification", dependent: :destroy

    has_secure_password
    before_validation :strip_whitespace
    before_create :set_jti
    after_create :create_default_lists

    validates :first_name, :last_name, :email, :date_of_birth, :country,
        presence: true

    validates :first_name, :last_name,
        length: { maximum: 50, minimum: 1 },
        format: { with: /\A[a-zA-Z]+\z/, message: "must contain only alphabets" }

    VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
    validates :email,
        length: { maximum: 254 },
        uniqueness: { case_sensitive: false },
        format: { with: VALID_EMAIL_REGEX }
    # format: { with: URI::MailTo::EMAIL_REGEXP }

    validates :country,
        numericality: { only_integer: true, greater_than: 0 },
        inclusion: { in: self::VALID_COUNTRY_NUMERIC_CODES, message: "is not a recognized country" }

    # Password policy:
    #   - required only when setting/changing the password (password_digest blank
    #     means an existing password is untouched, e.g. profile updates)
    #   - 8..128 characters (128 = bcrypt input limit safety)
    #   - at least one uppercase letter, one lowercase letter and one digit
    validates :password,
        presence: true,
        length: { minimum: 8, maximum: 128 },
        format: {
            with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+\z/,
            message: "must contain at least one uppercase letter, one lowercase letter and one digit"
        },
        if: -> { password_digest.blank? || password.present? }

    validate :validate_date_of_birth

    def as_json(options = {})
        super({ except: [ :password_digest ] }.merge(options))
    end

    def age
        return nil if date_of_birth.blank?

        today = Date.current

        birthday_this_year = begin
            date_of_birth.change(year: today.year)
        rescue Date::Error
            # If birthday is Feb 29 and current year is not leap year,
            # use March 1st as the effective birthday
            Date.new(today.year, 3, 1)
        end

        age = today.year - date_of_birth.year
        age -= 1 if today < birthday_this_year
        age
    end

    def full_name
        self.first_name.strip + " " + self.last_name.strip
    end

    def country_name
        ISO3166::Country.find_by_number(country.to_s)[1]["iso_short_name"]
    end

    def adult?
        age && age >= 18
    end

    def invalidate_auth_token
        update(jti: SecureRandom.uuid)
    end

    # def validate_email_domain
    #     return if email.blank?

    #     VALID_EMAIL_DOMAINS.each do |domain|
    #         return if email.include?(domain)
    #     end

    #     errors.add(:email, "domain is not supported")
    # end

    def verified?
        verification&.verified? || false
    end

    def create_verification_record
        build_verification(
            otp_code: UserVerification.generate_otp,
            otp_expires_at: 10.minutes.from_now
        ).tap(&:save!)
    end

    private

    # Callbacks
    def create_default_lists
        [ "watchlist", "watched", "favourite_movies", "favourite_tv_Shows" ].each do |name|
            lists.create!(
                type: "DefaultList",
                name: name,
                private: false,
                description: "Your #{name} collection"
            )
        end
    end

    def set_jti
        self.jti = SecureRandom.uuid
    end

    def strip_whitespace
        self.first_name = first_name.strip if first_name.present?
        self.last_name = last_name.strip if last_name.present?
        self.email = email.strip if email.present?
    end

    # Custom Validations
    def validate_date_of_birth
        return if date_of_birth.blank?

        if date_of_birth >= Date.current
            errors.add(:date_of_birth, "can not be today or a future date")
            return
        end

        if date_of_birth < 120.years.ago
            errors.add(:date_of_birth, "are you kidding me? You are too old!")
        end
    end
end
