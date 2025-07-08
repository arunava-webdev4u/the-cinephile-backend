require 'rails_helper'

RSpec.describe DefaultList, type: :model do
    # it_behaves_like "a list"

    describe "validations" do
        let(:user) { create(:user) }
        let(:default_list) { create(:default_list, user_id: user.id) }

        context "type validations" do
            it "is valid when type is DefaultList" do
                default_list.type = "DefaultList"
                expect(default_list).to be_valid
            end
        end
    end

    describe "instance methods" do
        let(:user) { create(:user) }
        let(:default_list) { create(:default_list, user_id: user.id) }

        describe "#can_be_created?" do
            it "returns false" do
                expect(default_list.can_be_created?).to be false
            end
        end

        describe "#can_be_deleted?" do
            it "returns false" do
                expect(default_list.can_be_deleted?).to be false
            end
        end

        describe "#can_be_updated?" do
            it "returns false" do
                expect(default_list.can_be_updated?).to be false
            end
        end
    end

  # describe 'business logic' do
  #     let(:user) { create(:user) }
  #     let(:default_list) { create(:default_list, user_id: user.id) }
  # end
end
