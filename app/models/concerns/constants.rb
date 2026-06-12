module Constants
    extend ActiveSupport::Concern

    included do
        # Add any instance methods or callbacks here if needed
    end

    class_methods do
        VALID_COUNTRY_NUMERIC_CODES = ISO3166::Country.all.map { |c| c.number.to_i }.freeze
    end
end