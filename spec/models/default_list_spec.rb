require 'rails_helper'

RSpec.describe DefaultList, type: :model do
    # ── Base List behaviour (validations, scopes, callbacks, belongs_to user) ──
    # DefaultList inherits all base List validations, so we run the shared suite.
    # NOTE: The "a list" shared example uses a :custom_list factory internally
    # (scopes/callbacks specs create both types via List), which is fine — those
    # tests are about the List base class, not the subtype factory used.
    it_behaves_like "a list"

    # ── Shared subtype behaviour (associations + CRUD permissions) ─────────────
    # DefaultList is read-only — all three permission guards return false.
    # The user's after_create callback seeds 4 default lists, so destroying
    # the user wipes all of them (count change = -user.lists.count evaluated
    # after the list is persisted but before destroy).
    it_behaves_like "a list subtype",
        factory:        :default_list,
        can_be_created: false,
        can_be_deleted: false,
        can_be_updated: false,
        destroyed_count: -> { -user.lists.count }  # auto-seeded defaults + 1 explicit

    # ── DefaultList-specific validations ───────────────────────────────────────
    describe "validations" do
        let(:user)         { create(:user) }
        let(:default_list) { create(:default_list, user_id: user.id) }

        context "name validations — only predefined names are allowed" do
            %w[watchlist watched favourite_movies favourite_tv_Shows].each do |valid_name|
                it "is valid with name '#{valid_name}'" do
                    default_list.name = valid_name
                    expect(default_list).to be_valid
                end
            end

            it "is invalid with an arbitrary name" do
                default_list.name = "my-custom-watchlist"
                expect(default_list).not_to be_valid
                expect(default_list.errors[:name]).to include("must be one of the predefined default list names")
            end

            it "is case-sensitive — 'Watchlist' is not valid" do
                default_list.name = "Watchlist"
                expect(default_list).not_to be_valid
                expect(default_list.errors[:name]).to include("must be one of the predefined default list names")
            end
        end

        context "type validations" do
            it "is valid when type is DefaultList" do
                default_list.type = "DefaultList"
                expect(default_list).to be_valid
            end
        end
    end

    # ── DefaultList-specific behaviour ─────────────────────────────────────────
    describe "CRUD permissions compared to CustomList" do
        let(:user)         { create(:user) }
        let(:default_list) { create(:default_list, user_id: user.id) }
        let(:custom_list)  { create(:custom_list,  user_id: user.id) }

        it "has the opposite CRUD permissions to CustomList" do
            expect(default_list.can_be_created?).to be false
            expect(default_list.can_be_deleted?).to be false
            expect(default_list.can_be_updated?).to be false

            expect(custom_list.can_be_created?).to be true
            expect(custom_list.can_be_deleted?).to be true
            expect(custom_list.can_be_updated?).to be true
        end
    end
end
