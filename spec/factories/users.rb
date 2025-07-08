FactoryBot.define do
  factory :user do
    first_name { "Sadie" }
    last_name { "Adler" }
    email { "sadieadler@gmail.com" }
    date_of_birth { Date.new(2001, 7, 25) }
    country { 5 }
    password { "super-secure-password" }
  end
end
