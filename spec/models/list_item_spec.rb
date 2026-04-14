require 'rails_helper'

# ---------------------------------------------------------------------------
# Shared examples — defined at the top level so they can be included
# in any describe/context block (per RSpec shared examples convention https://rspec.info/features/3-13/rspec-core/example-groups/shared-examples/).
# ---------------------------------------------------------------------------
RSpec.shared_examples "a list item belonging to any list" do |list_factory|
  let(:user) { create(:user) }
  let(:list) { create(list_factory, user_id: user.id) }

  # ── Validations ────────────────────────────────────────────────────────────
  describe "validations" do
    it "is valid with a list, item_id, and item_type" do
      item = ListItem.new(list: list, item_id: 550, item_type: "movie")
      expect(item).to be_valid
    end

    it "is invalid without a list" do
      item = ListItem.new(item_id: 1, item_type: "movie")
      expect(item).not_to be_valid
      expect(item.errors[:list]).to include("must exist")
    end
  end

  # ── Associations ───────────────────────────────────────────────────────────
  describe "associations" do
    it "belongs to a list" do
      association = ListItem.reflect_on_association(:list)
      expect(association.macro).to eq(:belongs_to)
    end

    it "is destroyed when its parent list is destroyed" do
      ListItem.create!(list: list, item_id: 1, item_type: "movie")
      expect { list.destroy }.to change { ListItem.count }.by(-1)
    end
  end

  # ── Persistence ────────────────────────────────────────────────────────────
  describe "persistence" do
    it "stores item_id and item_type correctly" do
      item = ListItem.create!(list: list, item_id: 550, item_type: "movie")
      reloaded = ListItem.find(item.id)
      expect(reloaded.item_id).to eq(550)
      expect(reloaded.item_type).to eq("movie")
    end

    it "can hold multiple items in the same list" do
      ListItem.create!(list: list, item_id: 1, item_type: "movie")
      ListItem.create!(list: list, item_id: 2, item_type: "movie")
      expect(list.list_items.count).to eq(2)
    end
  end
end

# ---------------------------------------------------------------------------
# ListItem spec — runs the shared behaviour for each list type
# ---------------------------------------------------------------------------
RSpec.describe ListItem, type: :model do
  context "when the list is a CustomList" do
    include_examples "a list item belonging to any list", :custom_list
  end

  context "when the list is a DefaultList" do
    include_examples "a list item belonging to any list", :default_list
  end
end
