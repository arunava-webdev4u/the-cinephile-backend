class CreateUserVerifications < ActiveRecord::Migration[8.0]
  def change
    create_table :user_verifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :otp_code, null: false
      t.datetime :otp_expires_at, null: false
      t.boolean :verified, null: false, default: false
      t.datetime :verified_at

      t.timestamps
    end
  end
end
