require 'rails_helper'

RSpec.describe CustomList, type: :model do
    # ── Base List behaviour (validations, scopes, callbacks, belongs_to user) ──
    it_behaves_like "a list"

    # ── Shared subtype behaviour (associations + CRUD permissions) ─────────────
    # CustomList supports full CRUD — all three permission guards return true.
    # A single CustomList is created per user, so destroying the user removes
    # exactly that 1 record from the CustomList table.
    it_behaves_like "a list subtype",
        factory:        :custom_list,
        can_be_created: true,
        can_be_deleted: true,
        can_be_updated: true,
        destroyed_count: -> { -1 }

    # ── CustomList-specific validations ────────────────────────────────────────
    describe "validations" do
        let(:user)        { create(:user) }
        let(:custom_list) { create(:custom_list, user_id: user.id) }

        context "name validations" do
            it "allows alphanumeric names with spaces and hyphens" do
                custom_list.name = "My-Watchlist 2025"
                expect(custom_list).to be_valid
            end
        end

        context "type validations" do
            it "is valid when type is CustomList" do
                custom_list.type = "CustomList"
                expect(custom_list).to be_valid
            end

            it "is invalid when type is set to an unknown value" do
                custom_list.type = "Bogus"
                expect(custom_list).not_to be_valid
                expect(custom_list.errors[:type]).to include("must be one of: DefaultList, CustomList")
            end
        end
    end
end
