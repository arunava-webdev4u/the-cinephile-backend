class CreateListItems < ActiveRecord::Migration[8.0]
  def change
    create_table :list_items do |t|
      t.references :list, null: false, foreign_key: true
      t.bigint :item_id, null: false
      t.string :item_type, null: false

      t.timestamps
    end
  end
end
