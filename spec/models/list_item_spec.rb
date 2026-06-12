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

    it "is invalid without a item_id" do
      item = ListItem.new(list: list, item_id: nil, item_type: "movie")
      expect(item).not_to be_valid
      expect(item.errors[:item_id]).to include("can't be blank")
    end

    it "is invalid with wrong item_id is not number" do
      item = ListItem.new(list: list, item_id: "not_a_number", item_type: "movie")
      expect(item).not_to be_valid
      expect(item.errors[:item_id]).to include("is not a number")
    end

    it "is invalid with item_id zero" do
      item = ListItem.new(list: list, item_id: 0, item_type: "movie")
      expect(item).not_to be_valid
      expect(item.errors[:item_id]).to include("must be greater than 0")
    end

    it "is invalid with negative item_id" do
      item = ListItem.new(list: list, item_id: -1, item_type: "movie")
      expect(item).not_to be_valid
      expect(item.errors[:item_id]).to include("must be greater than 0")
    end

    it "is invalid without a item_type" do
      item = ListItem.new(list: list, item_id: 550, item_type: nil)
      expect(item).not_to be_valid
      expect(item.errors[:item_type]).to include("can't be blank")
    end

    it "is invalid with an unsupported item_type" do
      item_types = [ "movie", "tv_show" ].freeze
      item = ListItem.new(list: list, item_id: 550, item_type: "book")
      expect(item).not_to be_valid
      expect(item.errors[:item_type]).to include("must be one of #{item_types.join(', ')}")
    end

    describe "#item_type_selection validation" do
      it "accepts 'movie' as a valid item_type" do
        item = ListItem.new(list: list, item_id: 550, item_type: "movie")
        expect(item).to be_valid
        expect(item.errors[:item_type]).to be_empty
      end

      it "accepts 'tv_show' as a valid item_type" do
        item = ListItem.new(list: list, item_id: 550, item_type: "tv_show")
        expect(item).to be_valid
        expect(item.errors[:item_type]).to be_empty
      end

      it "rejects 'book' as an invalid item_type" do
        item = ListItem.new(list: list, item_id: 550, item_type: "book")
        expect(item).not_to be_valid
        expect(item.errors[:item_type]).to include("must be one of movie, tv_show")
      end

      it "rejects 'show' as an invalid item_type" do
        item = ListItem.new(list: list, item_id: 550, item_type: "show")
        expect(item).not_to be_valid
        expect(item.errors[:item_type]).to include("must be one of movie, tv_show")
      end

      it "rejects 'music' as an invalid item_type" do
        item = ListItem.new(list: list, item_id: 550, item_type: "music")
        expect(item).not_to be_valid
        expect(item.errors[:item_type]).to include("must be one of movie, tv_show")
      end

      it "rejects empty string as an invalid item_type" do
        item = ListItem.new(list: list, item_id: 550, item_type: "")
        expect(item).not_to be_valid
        expect(item.errors[:item_type]).to include("can't be blank")
      end

      it "provides a helpful error message with valid options" do
        item = ListItem.new(list: list, item_id: 550, item_type: "invalid")
        item.valid?
        error_message = item.errors[:item_type].first
        expect(error_message).to include("movie")
        expect(error_message).to include("tv_show")
      end
    end
  end

  # ── Callbacks ──────────────────────────────────────────────────────────────
  describe "callbacks" do
    describe "#downcase_item_type before_validation" do
      it "converts 'MOVIE' to lowercase 'movie'" do
        item = ListItem.new(list: list, item_id: 550, item_type: "MOVIE")
        item.valid?
        expect(item.item_type).to eq("movie")
      end

      it "converts 'TV_SHOW' to lowercase 'tv_show'" do
        item = ListItem.new(list: list, item_id: 550, item_type: "TV_SHOW")
        item.valid?
        expect(item.item_type).to eq("tv_show")
      end

      it "converts 'Movie' (mixed case) to lowercase 'movie'" do
        item = ListItem.new(list: list, item_id: 550, item_type: "Movie")
        item.valid?
        expect(item.item_type).to eq("movie")
      end

      it "converts 'Tv_Show' (mixed case) to lowercase 'tv_show'" do
        item = ListItem.new(list: list, item_id: 550, item_type: "Tv_Show")
        item.valid?
        expect(item.item_type).to eq("tv_show")
      end

      it "keeps already lowercase 'movie' unchanged" do
        item = ListItem.new(list: list, item_id: 550, item_type: "movie")
        item.valid?
        expect(item.item_type).to eq("movie")
      end

      it "keeps already lowercase 'tv_show' unchanged" do
        item = ListItem.new(list: list, item_id: 550, item_type: "tv_show")
        item.valid?
        expect(item.item_type).to eq("tv_show")
      end

      it "converts case before validation, allowing validation to pass" do
        item = ListItem.new(list: list, item_id: 550, item_type: "MOVIE")
        expect(item).to be_valid
        expect(item.item_type).to eq("movie")
      end

      it "converts case before validation for tv_show" do
        item = ListItem.new(list: list, item_id: 550, item_type: "TV_SHOW")
        expect(item).to be_valid
        expect(item.item_type).to eq("tv_show")
      end

      it "handles nil item_type gracefully without error" do
        item = ListItem.new(list: list, item_id: 550, item_type: nil)
        expect { item.valid? }.not_to raise_error
        expect(item.item_type).to be_nil
      end

      it "persists the downcased item_type to the database" do
        item = ListItem.create!(list: list, item_id: 550, item_type: "MOVIE")
        reloaded = ListItem.find(item.id)
        expect(reloaded.item_type).to eq("movie")
      end

      it "persists downcased tv_show to the database" do
        item = ListItem.create!(list: list, item_id: 550, item_type: "TV_SHOW")
        reloaded = ListItem.find(item.id)
        expect(reloaded.item_type).to eq("tv_show")
      end
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

    it "allows the same item_id in different lists" do
      another_list = create(list_factory, user_id: user.id)
      item1 = ListItem.create!(list: list, item_id: 550, item_type: "movie")
      item2 = ListItem.create!(list: another_list, item_id: 550, item_type: "movie")
      expect(item1).to be_persisted
      expect(item2).to be_persisted
    end

    it "stores very large item_id correctly" do
      large_id = 999_999_999
      item = ListItem.create!(list: list, item_id: large_id, item_type: "tv_show")
      reloaded = ListItem.find(item.id)
      expect(reloaded.item_id).to eq(large_id)
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
