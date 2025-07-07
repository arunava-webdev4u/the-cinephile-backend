require 'rails_helper'

RSpec.describe List, type: :model do

  describe 'validations' do
    let(:user) { create(:user) }
    let(:custom_list) { create(:custom_list, user_id: user.id) }
    
    it "is valid with valid attributes" do
      expect(custom_list).to be_valid
    end

    context "name validations" do
      it "can not be empty" do
        custom_list.name = nil
        expect(custom_list).not_to be_valid
      end

      it "can not be longer than 50 characters long" do
        custom_list.name = "kjahslkdfhaskjdhfalkksjdhflakshfalksfhlskdfhalsjfhaslkfhaslkfhasdlkfhasddfhasldfhasldfasldfgasdlfgasldfgaslfgs"
        expect(custom_list).not_to be_valid
      end

      it "can not be empty string" do
        custom_list.name = ""
        expect(custom_list).not_to be_valid
      end
      
      it "should only contain alphabets, hyphens & numbers" do
        custom_list.name = "my-custom-list 123"
        expect(custom_list).to be_valid
      end

      it "should not contain any kind of special characters other than hyphen" do
        custom_list.name = "my#custom_list@123.?"
        expect(custom_list).not_to be_valid
      end
    end

    context "description validations" do
      it "can be empty" do
        custom_list.description = nil
        expect(custom_list).to be_valid
      end

      it "can not be longer than 250 characters long" do
        custom_list.description = "a"*251
        expect(custom_list).not_to be_valid
      end

      it "is valid with valid characters in the description" do
        custom_list.description = ""
        expect(custom_list).to be_valid
      end

    it "is not valid with valid characters in the description" do
        custom_list.description = "<html><h1>hey there !</h1></html>"
        expect(custom_list).not_to be_valid
      end
    end
    
    context "type validations" do
      it "can be empty" do
        custom_list.type = nil
        expect(custom_list).not_to be_valid
      end

      it "is valid when type is DefaultList" do
        custom_list.type = "DefaultList"
        expect(custom_list).to be_valid
      end
      
      it "is valid when type is CustomList" do
        custom_list.type = "CustomList"
        expect(custom_list).to be_valid
      end

      it "is not valid when type is empty" do
        custom_list.type = ""
        expect(custom_list).not_to be_valid
      end

      it "is not valid when type is unknown" do
        valid_types = ['DefaultList', 'CustomList'].freeze
        custom_list.type = "FunnyType"
        expect(custom_list).not_to be_valid
        expect(custom_list.errors.messages[:type].first).to eq "must be one of: #{valid_types.join(', ')}"
      end
    end

    context "private validations" do
      # it "is valid when true" do
      # end

      # it "is valid when false" do
      # end

      # it "is valid when nil" do
      # end

      # it "is stores default value when nil" do
      # end
    end
    
    context "user validations" do
      # it "is invalid without a user" do
      # end

      # it "is integer only" do
      # end
    end
  end

  # describe 'associations' do
  #   it 'belongs to a user' do
  #     association = described_class.reflect_on_association(:user)
  #     expect(association.macro).to eq(:belongs_to)
  #   end

  #   it 'has many items' do
  #     association = described_class.reflect_on_association(:items)
  #     expect(association.macro).to eq(:has_many)
  #   end
  # end
  
  # describe 'scopes' do
  #   let!(:user1) { create(:user) }
  #   let!(:user2) { create(:user) }
  #   let!(:default_list1) { create(:default_list, user: user1) }
  #   let!(:default_list2) { create(:default_list, user: user2) }

  #   it 'returns lists for a specific user' do
  #     expect(user1.default_lists).to include(default_list1)
  #     expect(user1.default_lists).to_not include(default_list2)
  #   end
  # end

  # describe 'business logic' do
  #   let(:default_list) { create(:default_list) }

  #   it 'cannot be deleted if it has items' do
  #     create(:item, list: default_list)
  #     expect { default_list.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
  #   end

  #   it 'can be deleted if it has no items' do
  #     expect { default_list.destroy! }.to_not raise_error
  #   end

  #   it 'returns correct type' do
  #     expect(default_list.type).to eq('DefaultList')
  #   end
  # end
end
