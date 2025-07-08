require 'rails_helper'

RSpec.describe DefaultList, type: :model do
    it_behaves_like "a list"

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
end