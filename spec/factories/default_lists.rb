FactoryBot.define do
  factory :default_list do
    user_id { 1 }
    type { "DefaultList" }
    name { "watchlist" }
    description { "Test Description" }
    private { true }
  end
end
