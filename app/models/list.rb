class List < ApplicationRecord
    belongs_to :user

    # validates :name, presence: true, length: { maximum: 100 }
    # validates :description, length: { maximum: 500 }

    scope :public_lists, -> { where(private: false) }
    scope :private_lists, -> { where(private: true) }

    def can_be_deleted?
        true
    end

    def can_be_updated?
        true
    end

    def display_name
        name
    end
end
