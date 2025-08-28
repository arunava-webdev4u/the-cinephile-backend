class DropPendingRegistrationsTable < ActiveRecord::Migration[8.0]
  def up
    drop_table :pending_registrations
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
