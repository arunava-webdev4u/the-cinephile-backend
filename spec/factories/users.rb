FactoryBot.define do
  factory :user do
    first_name { "John" }
    last_name  { "Doe" }
    email { Faker::Internet.unique.email }
    country { 356 } # India
    date_of_birth { 25.years.ago }
    password { "Password123_" }
  end
end
