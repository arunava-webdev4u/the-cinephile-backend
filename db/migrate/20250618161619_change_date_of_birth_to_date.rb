class ChangeDateOfBirthToDate < ActiveRecord::Migration[8.0]
  def up
    # Step 1: Add a temporary column
    add_column :users, :date_of_birth_temp, :date

    # Step 2: Convert existing data
    User.reset_column_information
    User.find_each do |user|
      begin
        # Try to parse the existing string date
        parsed_date = Date.parse(user.date_of_birth) if user.date_of_birth.present?
        user.update_column(:date_of_birth_temp, parsed_date)
      rescue ArgumentError
        # Handle invalid dates - you might want to set a default or skip
        puts "Invalid date for user #{user.id}: #{user.date_of_birth}"
        # Optionally set a default date or leave as nil
        # user.update_column(:date_of_birth_temp, Date.new(2000, 1, 1))
      end
    end

    # Step 3: Remove old column and rename new one
    remove_column :users, :date_of_birth
    rename_column :users, :date_of_birth_temp, :date_of_birth

    # Step 4: Add null constraint
    change_column_null :users, :date_of_birth, false
  end

  def down
    # Convert back to string
    change_column :users, :date_of_birth, :string, null: false
  end
end
