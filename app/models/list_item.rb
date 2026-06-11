class ListItem < ApplicationRecord
  belongs_to :list

  # Write specs for validations
  validates :item_id, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :item_type, presence: true

  validate :item_type_selection

  def item_type_selection
    item_types = [ "movie", "tv_show" ].freeze
    unless item_types.include?(item_type)
      errors.add(:item_type, "must be one of #{item_types.join(', ')}")
    end
  end
end
