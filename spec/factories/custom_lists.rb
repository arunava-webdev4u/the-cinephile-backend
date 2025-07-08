FactoryBot.define do
  factory :custom_list do
    user_id { 1 }
    type { "CustomList" }
    name { "Test List" }
    description { "Test Description" }
    private { true }
  end
end
