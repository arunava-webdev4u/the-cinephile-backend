class RemoveVerifiedFromUserVerifications < ActiveRecord::Migration[8.0]
  def change
    remove_column :user_verifications, :verified, :boolean
  end
end
