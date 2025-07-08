# require 'rails_helper'

RSpec.shared_examples "a list" do
    describe 'validations' do
        let(:user) { create(:user) }
        let(:list) { create(:custom_list, user_id: user.id) }

        it "is valid with valid attributes" do
            expect(list).to be_valid
        end

        context "name validations" do
            it "can not be empty" do
                list.name = nil
                expect(list).not_to be_valid
            end

            it "can not be longer than 50 characters long" do
                list.name = "kjahslkdfhaskjdhfalkksjdhflakshfalksfhlskdfhalsjfhaslkfhaslkfhasdlkfhasddfhasldfhasldfasldfgasdlfgasldfgaslfgs"
                expect(list).not_to be_valid
            end

            it "can not be empty string" do
                list.name = ""
                expect(list).not_to be_valid
            end

            it "should only contain alphabets, hyphens & numbers" do
                list.name = "my-custom-list 123"
                expect(list).to be_valid
            end

            it "should not contain any kind of special characters other than hyphen" do
                list.name = "my#custom_list@123.?"
                expect(list).not_to be_valid
            end
        end

        context "description validations" do
            it "can be empty" do
                list.description = nil
                expect(list).to be_valid
            end

            it "can not be longer than 250 characters long" do
                list.description = "a"*251
                expect(list).not_to be_valid
            end

            it "is valid with valid characters in the description" do
                valid_descriptions = [
                    "A simple description",
                    "Description with numbers: 123",
                    "With punctuation: .,;?!()[]{}",
                    "With quotes: 'single' and \"double\"",
                    ""
                ]
                valid_descriptions.each do |desc|
                    list.description = desc
                    expect(list).to be_valid
                end
            end

            it "is not valid with valid characters in the description" do
                list.description = "<html><h1>hey there !</h1></html>"
                expect(list).not_to be_valid
            end
        end

        context "type validations" do
            it "can be empty" do
                list.type = nil
                expect(list).not_to be_valid
            end

            it "is not valid when type is empty" do
                list.type = ""
                expect(list).not_to be_valid
            end
        end

        context "private validations" do
            it "is valid when true" do
                list.private = true
                expect(list).to be_valid
            end

            it "is valid when false" do
                list.private = false
                expect(list).to be_valid
            end

            it "is valid when nil" do
                list.private = nil
                expect(list).to be_valid
            end

            it "is stores default value when nil" do
                list.private = nil
                expect(list).to be_valid
                expect(list.private).to equal(false)
            end
        end

        context "user validations" do
            it "is invalid without a user" do
                list.user_id = nil
                expect(list).not_to be_valid
            end

            it "is integer only" do
                list.user_id = "5"
                expect(list).not_to be_valid
                expect(list.errors.messages[:user]).to include("must exist")
            end
        end
    end

    describe 'custom validation' do
        let(:user) { create(:user) }
        let(:list) { create(:custom_list, user_id: user.id) }

        context "list_type_must_be_valid" do
            it "is not valid when type is unknown" do
                valid_types = [ 'DefaultList', 'CustomList' ].freeze
                invalid_types = [ "InvalidType", "defaultlist", "customlist", "Defaultlist", "Customlist", "defaultList", "customList" ]

                invalid_types.each do |invalid_type|
                    list.type = invalid_type
                    expect(list).not_to be_valid
                    expect(list.errors.messages[:type].first).to include("must be one of: #{valid_types.join(', ')}")
                end
            end
        end
    end

    describe 'associations' do
        let(:user) { create(:user) }
        let(:list) { create(:list, user_id: user.id) }

        it 'belongs to a user' do
        association = described_class.reflect_on_association(:user)
        expect(association.macro).to eq(:belongs_to)
        end

      # it 'has many items' do
      #     association = described_class.reflect_on_association(:items)
      #     expect(association.macro).to eq(:has_many)
      # end
    end

    describe "scopes" do
        let(:user) { create(:user) }

        let(:public_list_1) { create(:custom_list, private: false, user_id: user.id) }
        let(:private_list_1) { create(:custom_list, private: true, user_id: user.id) }
        let(:private_list_2) { create(:custom_list, private: true, user_id: user.id) }

        let(:default_list) { create(:default_list, user_id: user.id) }
        let(:custom_list) { create(:custom_list, user_id: user.id) }

        context ".public_lists" do
            it "returns only public lists" do
                expect(List.public_lists).to include(public_list_1)
                expect(List.public_lists).not_to include(private_list_1, private_list_2)
                expect(List.public_lists).to all(have_attributes(private: false))
            end
        end

        context ".private_lists" do
            it "returns only private lists" do
                expect(List.private_lists).to include(private_list_1, private_list_2)
                expect(List.private_lists).not_to include(public_list_1)
                expect(List.private_lists).to all(have_attributes(private: true))
            end
        end

        context ".default_lists" do
            it "returns only default lists" do
                expect(List.default_lists).to include(default_list)
                expect(List.default_lists).to all(have_attributes(type: 'DefaultList'))
            end
        end

        context ".custom_lists" do
            it "returns only custom lists" do
                expect(List.custom_lists).to include(custom_list)
                expect(List.custom_lists).to all(have_attributes(type: 'CustomList'))
            end
        end
    end

    describe "callbacks" do
        let(:user) { create(:user) }

        context "before_validation :set_default_private" do
            let(:private_list_nil) { create(:custom_list, private: nil, user_id: user.id) }
            let(:private_list_true) { create(:custom_list, private: true, user_id: user.id) }
            let(:private_list_false) { create(:custom_list, private: false, user_id: user.id) }

            it "sets private to false when nil" do
                expect(private_list_nil.private).to be false
            end

            it "doesn't change private when already set to true" do
                expect(private_list_true.private).to be true
            end

            it "doesn't change private when already set to false" do
                expect(private_list_false.private).to be false
            end
        end
    end
end
