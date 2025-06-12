class User < ApplicationRecord
    has_secure_password

    before_validation :strip_whitespace

    validates :first_name, :last_name, :email, :date_of_birth, :country,
        presence: true

    validates :first_name, :last_name,
        length: { maximum: 50, minimum: 1 },
        format: { with: /\A[a-zA-Z]+\z/, message: "must contain only alphabets" }

    validates :email,
        length: { maximum: 254 },
        uniqueness: { case_sensitive: false },
        format: { with: URI::MailTo::EMAIL_REGEXP }

    validates :country,
        numericality: { only_integer: true, greater_than: 0 }

    # validates :country, format: { with: /........../, message: "........" }, inclusion: { in: COUNTRIES, message: "is not in our country list" }

    validate :validate_date_of_birth

    def age
        ((Date.current - date_of_birth) / 365.25).floor
    end

    def full_name
        (self.first_name + " " + self.last_name).strip
    end

    def adult?
        age && age >= 18
    end

    def strip_whitespace
        self.first_name = first_name.strip if first_name.present?
        self.last_name = last_name.strip if last_name.present?
        self.email = email.strip if email.present?
    end

    def validate_date_of_birth
        return if date_of_birth.blank?

        unless date_of_birth.is_a?(Date)
            errors.add(:date_of_birth, "must be a valid date")
            return
        end
        # need to revisit this validation later

        if date_of_birth > Date.current
            errors.add(:date_of_birth, "can not be today or a future date")
            return
        end

        if date_of_birth < 120.years.ago
            errors.add(:date_of_birth, "must be within the last 120 years")
        end
    end

    # Override as_json to exclude sensitive fields
    def as_json(options = {})
        super(options.merge(except: [ :password_digest ]))
    end

  # def validate_email_domain
  #     return if email.blank?

  #     VALID_EMAIL_DOMAINS.each do |domain|
  #         return if email.include?(domain)
  #     end

  #     errors.add(:email, "domain is not supported")
  # end

  # def create_fixed_lists
  #     FixedList.create(user: self, name: "WatchList")
  #     FixedList.create(user: self, name: "Watched")
  #     FixedList.create(user: self, name: "Favourite Movies")
  #     FixedList.create(user: self, name: "Favourite TV Shows")
  # end
end
