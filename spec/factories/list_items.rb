FactoryBot.define do
  factory :list_item do
    association :list, factory: :custom_list
    item_id { 550 }
    item_type { "Movie" }
  end
end
