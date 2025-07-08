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

  # describe "instance methods" do
  #     let(:list) { create(:list, valid_attributes) }

  #     describe "#can_be_deleted?" do
  #     it "returns true" do
  #         expect(list.can_be_deleted?).to be true
  #     end
  #     end

  #     describe "#can_be_updated?" do
  #     it "returns true" do
  #         expect(list.can_be_updated?).to be true
  #     end
  #     end

  #     describe "#display_name" do
  #     it "returns the name" do
  #         expect(list.display_name).to eq(list.name)
  #     end
  #     end
  # end

  # describe 'business logic' do
  #     let(:default_list) { create(:default_list) }

  #     it 'cannot be deleted if it has items' do
  #     create(:item, list: default_list)
  #     expect { default_list.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
  #     end

  #     it 'can be deleted if it has no items' do
  #     expect { default_list.destroy! }.to_not raise_error
  #     end

  #     it 'returns correct type' do
  #     expect(default_list.type).to eq('DefaultList')
  #     end
  # end
end
