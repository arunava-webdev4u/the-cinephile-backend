class AddNotNullConstraintToUsersTable < ActiveRecord::Migration[8.0]
  def change
    change_column :users, :email, :string, null: false
    change_column :users, :password_digest, :string, null: false
    change_column :users, :first_name, :string, null: false
    change_column :users, :last_name, :string, null: false
    change_column :users, :date_of_birth, :date, null: false
    change_column :users, :country, :integer, null: false
  end
end
