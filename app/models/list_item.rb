class ListItem < ApplicationRecord
  belongs_to :list

  # Write specs for validations
  validates :item_id, presence: true
end
