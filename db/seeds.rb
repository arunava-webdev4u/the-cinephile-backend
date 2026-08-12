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

# Delete old dev_creds.local.md file if it exists (skip if not present)
local_file_path = Rails.root.join('dev_creds.local.md')
begin
  File.delete(local_file_path) if File.exist?(local_file_path)
  puts "Deleted old dev_creds.local.md file."
rescue => e
  puts "Warning: Could not delete old .local.md file: #{e.message}"
end

# Initialize credentials data
credentials_data = []

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

  # Store credentials for .local.md file
  credentials_data << {
    name: "#{user.first_name} #{user.last_name}",
    email: user.email,
    password: password
  }

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
        item_type: [ "movie", "tv_show" ].sample
      )
      puts "    Created ListItem: #{(k + 1).to_s.rjust(2, '0')} for " + list.name + " (\#{list.type})"
    end
  end
end

puts "Seed data created successfully!"

# Write credentials to .local.md file
begin
  markdown_content = "# Test User Credentials\n\n"
  markdown_content += "Generated at: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}\n\n"
  markdown_content += "| Name | Email | Password |\n"
  markdown_content += "|------|-------|----------|\n"

  credentials_data.each do |cred|
    markdown_content += "| #{cred[:name]} | #{cred[:email]} | `#{cred[:password]}` |\n"
  end

  markdown_content += "\n---\n\n"
  markdown_content += "**Note:** This file is generated automatically by `bin/rails db:seed` and should NOT be committed to git.\n"
  markdown_content += "It contains test credentials for development purposes only.\n"

  File.write(local_file_path, markdown_content)
  puts "\n✓ Credentials saved to dev_creds.local.md"
rescue => e
  puts "\n✗ Error writing credentials to dev_creds.local.md: #{e.message}"
end
