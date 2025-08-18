class CreatePendingRegistrations < ActiveRecord::Migration[8.0]
  def change
    create_table :pending_registrations do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string "first_name", null: false
      t.string "last_name", null: false
      t.date "date_of_birth", null: false
      t.integer "country", null: false
      t.string "otp_code", null: false
      t.datetime "otp_expires_at", null: false
      t.boolean "verified", default: false
      t.timestamps
    end
  end
end
