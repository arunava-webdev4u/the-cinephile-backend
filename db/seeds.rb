require 'faker'

puts "Creating users and custom lists..."

# Ensure Faker is loaded and available
if !defined?(Faker)
  puts "Faker gem not found. Please add 'faker' to your Gemfile and run 'bundle install'."
  exit
end

# Clear existing data to prevent duplicates on re-seed
User.destroy_all
puts "Destroyed all existing users."

# Valid country codes from the ISO3166::Country gem, which is used in the User model
valid_country_codes = ISO3166::Country.all.map { |c| c.number.to_i }.compact.map(&:to_i)

10.times do |i|
  password = Faker::Internet.password(min_length: 10, max_length: 20)
  user = User.create!(
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    email: Faker::Internet.unique.email,
    password: password,
    password_confirmation: password,
    date_of_birth: Faker::Date.birthday(min_age: 18, max_age: 65),
    country: valid_country_codes.sample # Pick a random valid country code
  )
  puts "Created User: #{(i + 1).to_s.rjust(2, '0')} - #{user.email}"

  # Create a random number of custom lists for each user (3-6)
  rand(3..6).times do |j|
    user.lists.create!(
      name: Faker::Lorem.unique.word.capitalize + " List",
      type: "CustomList",
      description: Faker::Lorem.sentence(word_count: 5)
    )
    puts "  Created CustomList: #{(j + 1).to_s.rjust(2, '0')} for #{user.email}"
  end

  # Add ListItems to all lists (both default and custom)
  user.lists.each do |list|
    rand(5..15).times do |k|
      list.list_items.create!(
        item_id: Faker::Number.unique.between(from: 1, to: 100000),
        item_type: ["movie", "tv_show"].sample
      )
      puts "    Created ListItem: #{(k + 1).to_s.rjust(2, '0')} for " + list.name + " (\#{list.type})"
    end
  end
end

puts "Seed data created successfully!"