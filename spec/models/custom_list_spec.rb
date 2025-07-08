require 'rails_helper'

RSpec.describe DefaultList, type: :model do
    it_behaves_like "a list"

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
end