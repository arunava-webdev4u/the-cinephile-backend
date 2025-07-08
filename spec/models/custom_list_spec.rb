require 'rails_helper'

RSpec.describe DefaultList, type: :model do
    # it_behaves_like "a list"

    describe "validations" do
        let(:user) { create(:user) }
        let(:custom_list) { create(:custom_list, user_id: user.id) }

        context "type validations" do
            it "is valid when type is CustomList" do
                custom_list.type = "CustomList"
                expect(custom_list).to be_valid
            end
        end
    end

    describe "instance methods" do
        let(:user) { create(:user) }
        let(:custom_list) { create(:custom_list, user_id: user.id) }

        describe "#can_be_created?" do
            it "returns true" do
                expect(custom_list.can_be_created?).to be true
            end
        end

        describe "#can_be_deleted?" do
            it "returns true" do
                expect(custom_list.can_be_deleted?).to be true
            end
        end

        describe "#can_be_updated?" do
            it "returns true" do
                expect(custom_list.can_be_updated?).to be true
            end
        end
    end
end
