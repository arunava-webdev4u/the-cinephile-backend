require 'rails_helper'
require 'active_support/testing/time_helpers'

RSpec.describe User, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  describe 'validations' do
    let(:user) { create(:user) }

    it 'is valid with valid attributes' do
      expect(user).to be_valid
    end

    context 'first_name validations' do
      it 'can not be empty' do
        user.first_name = nil
        expect(user).not_to be_valid
        expect(user.errors[:first_name]).to include("can't be blank")
      end

      it 'must contain only alphabets' do
        user.first_name = 'John123'
        expect(user).not_to be_valid
        expect(user.errors[:first_name]).to include('must contain only alphabets')
      end

      it 'must be less than 50 characters' do
        user.first_name = "asdkkfjhasdfjhaslkfhaslfhaslfhaslfjashflkashflasfhasljgsfjasgljasgflsfgasdlkfgasfjasgfjasgflasjfgaslfgaslfgsdljfg"
        expect(user).not_to be_valid
        expect(user.errors[:first_name]).to include('is too long (maximum is 50 characters)')
      end

      it 'can not be an empty string' do
        user.first_name = ""
        expect(user).not_to be_valid
        expect(user.errors[:first_name]).to include('is too short (minimum is 1 character)')
      end
    end

    context 'last_name validations' do
      it 'can not be empty' do
        user.last_name = nil
        expect(user).not_to be_valid
        expect(user.errors[:last_name]).to include("can't be blank")
      end

      it 'must contain only alphabets' do
        user.last_name = 'Doe123'
        expect(user).not_to be_valid
        expect(user.errors[:last_name]).to include('must contain only alphabets')
      end

      it 'must be less than 50 characters' do
        user.last_name = "asdkkfjhasdfjhaslkfhaslfhaslfhaslfjashflkashflasfhasljgsfjasgljasgflsfgasdlkfgasfjasgfjasgflasjfgaslfgaslfgsdljfg"
        expect(user).not_to be_valid
        expect(user.errors[:last_name]).to include('is too long (maximum is 50 characters)')
      end

      it 'can not be an empty string' do
        user.last_name = ""
        expect(user).not_to be_valid
        expect(user.errors[:last_name]).to include('is too short (minimum is 1 character)')
      end
    end

    context 'email validations' do
      it 'is not valid without an email' do
        user.email = nil
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("can't be blank")
      end

      it 'can not be more than 254 characters long' do
        user.email = "#{'a'*80} #{'5'*80} #{'k'*80} #{'x'*80}@example.com"
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include('is too long (maximum is 254 characters)')
      end

      it 'is not valid with an invalid email' do
        invalid_emails = [
          'abc!%4&g.@gmail.com',
          'abc.gmail.com',
          'abc@',
          'abc@gmail',
          '@gmail.com',
          'abc@@gmail.com',
          'abc gmail@gmail.com',
          'invalid-email'
        ]

          invalid_emails.each do |invalid_email|
            user.email = invalid_email
            expect(user).not_to be_valid, "#{invalid_email.inspect} should be invalid"
            expect(user.errors[:email]).to include('is invalid')
          end
      end

      context 'when duplicate email' do
        let(:user_1) { create(:user, email: "abc@gmail.com") }

        it 'is not valid' do
          duplicate_user = build(:user, email: user_1.email)
          expect(user_1).to be_valid
          expect(duplicate_user).not_to be_valid
          expect(duplicate_user.errors[:email]).to include('has already been taken')
        end

        it 'is not valid with a case sensitivity' do
          duplicate_user = build(:user, email: user_1.email.split('@')[0].upcase)
          expect(user_1).to be_valid
          expect(duplicate_user).not_to be_valid
          expect(duplicate_user.errors[:email]).to include('is invalid')
          # expect(duplicate_user.errors[:email]).to include('has already been taken')
        end
      end

      ##### Future #####
      # it 'must have a supported email domain' do
      #   user.email = 'arunava.das@example.com'
      #   expect(user).not_to be_valid
      #   expect(user.errors[:email]).to include('domain is not supported')
      # end
    end

    # ###############################33
    # context "password validations" do
    # will implement in future
    # end

    context 'date_of_birth validations' do
      it 'is not valid without a date_of_birth' do
        user.date_of_birth = nil
        expect(user).not_to be_valid
        expect(user.errors[:date_of_birth]).to include("can't be blank")
      end

      it 'date_of_birth must be a valid date' do
        user.date_of_birth = 'abcd-xy-00'
        expect(user).not_to be_valid
      end

      it 'date_of_birth cant be a future date' do
        user.date_of_birth = Date.current + 1.day
        expect(user).not_to be_valid
        expect(user.errors[:date_of_birth]).to include('can not be today or a future date')
      end

      it 'can not be a ghost' do
        user.date_of_birth = Date.current-120.years
        expect(user).not_to be_valid
        expect(user.errors[:date_of_birth]).to include("are you kidding me? You are too old!")
      end
    end

    context 'country validations' do
      it 'must be present' do
        user.country = nil
        expect(user).not_to be_valid
        expect(user.errors[:country]).to include("can't be blank")
      end

      context 'data type validation' do
        it 'must be a number' do
          user.country = 'canada'
          expect(user).not_to be_valid
          expect(user.errors[:country]).to include("is not a number")
        end

        it 'must be a whole number' do
          user.country = 5.782
          expect(user).not_to be_valid
          expect(user.errors[:country]).to include("must be an integer")
        end

        it 'must be a greater thatn 0' do
          user.country = -5
          expect(user).not_to be_valid
          expect(user.errors[:country]).to include("must be greater than 0")
        end
      end

      # ######## Future #########
      # it 'must be in our country list' do
      #   user.country = 'Tiwan'
      #   expect(user).not_to be_valid
      #   expect(user.errors[:country]).to include('is not in our country list')
      # end
    end

    describe 'custom validation' do
      # ##################################
      describe '#validate_date_of_birth' do
        let(:user) { build(:user) }

        it 'is valid with a reasonable past date' do
          user.date_of_birth = 30.years.ago.to_date
          expect(user).to be_valid
        end

        it 'is invalid if date_of_birth is in the future' do
          user.date_of_birth = Date.current + 1.day
          expect(user).not_to be_valid
          expect(user.errors[:date_of_birth]).to include("can not be today or a future date")
        end

        it 'is invalid if date_of_birth is more than 120 years ago' do
          user.date_of_birth = 121.years.ago.to_date
          expect(user).not_to be_valid
          expect(user.errors[:date_of_birth]).to include("are you kidding me? You are too old!")
        end

        it 'is invalid if date_of_birth is today' do
          user.date_of_birth = Date.today
          expect(user).not_to be_valid
          expect(user.errors[:date_of_birth]).to include("can not be today or a future date")
        end

        it 'is valid if date_of_birth is exactly 120 years ago' do
          user.date_of_birth = 120.years.ago.to_date
          expect(user).not_to be_valid
        end
      end
    end

    describe 'callbacks' do
      describe 'before_validation :strip_whitespace' do
        let(:user) { create(:user, first_name: '  John  ', last_name: '  Doe  ', email: "  abc@gmail.com    ") }

        it 'strips whitespace from names' do
          user.valid?
          expect(user.first_name).to eq('John')
          expect(user.last_name).to eq('Doe')
          expect(user.email).to eq('abc@gmail.com')
        end
      end

      describe 'before_create :set_jti' do
        it 'sets the jti to a UUID before creation' do
          user = create(:user)
          expect(user.jti).to be_present
          expect(user.jti).to match(/\A[\w\d\-]{36}\z/)
        end
      end

      describe 'after_create :create_default_lists' do
        it 'creates default lists for the user after creation' do
          user = create(:user)
          expect(user.lists.count).to eq(4)
          expected_names = [ "watchlist", "watched", "favourite_movies", "favourite_tv_Shows" ]
          expect(user.lists.pluck(:name)).to match_array(expected_names)
          expect(user.lists.pluck(:type).uniq).to eq([ "DefaultList" ])
          expect(user.lists.pluck(:private).uniq).to eq([ false ])
        end
      end
    end

    describe 'instance methods' do
      describe '#full_name' do
        it 'returns first and last name combined' do
          user = build(:user, first_name: 'John', last_name: 'Doe')
          expect(user.full_name).to eq(user.first_name + ' ' + user.last_name)
        end

        it 'strips extra whitespace' do
          user = build(:user, first_name: ' John  ', last_name: '  Doe  ')
          expect(user.full_name).to eq('John Doe')
        end
      end

      describe '#age' do
        let(:user) { build(:user) }
        after { travel_back }

        it 'returns the correct age when birthday is today' do
          travel_to Date.new(2025, 6, 12) do
            user.date_of_birth = Date.new(2000, 6, 12)
            expect(user.age).to eq(25)
          end
        end

        it 'returns the correct age when birthday has not occurred yet this year' do
          travel_to Date.new(2025, 6, 12) do
            user.date_of_birth = Date.new(2000, 10, 1)
            expect(user.age).to eq(24)
          end
        end

        it 'returns the correct age when birthday already occurred this year' do
          travel_to Date.new(2025, 6, 12) do
            user.date_of_birth = Date.new(2000, 2, 1)
            expect(user.age).to eq(25)
          end
        end

        context 'when date_of_birth is Feb 29 on a leap year' do
          it 'returns the correct age on a non-leap year' do
            user.date_of_birth = Date.new(2004, 2, 29)  # Leap year birthday

            # Travel to a non-leap year like 2025-02-28 (day before leap day)
            travel_to Date.new(2025, 2, 28) do
              expect(user.age).to eq(20)
            end

            # Travel to 2025-03-01 (effectively birthday celebration day)
            travel_to Date.new(2025, 3, 1) do
              expect(user.age).to eq(21)
            end
          end

          it 'returns the correct age on a leap year' do
            user.date_of_birth = Date.new(2004, 2, 29)

            travel_to Date.new(2024, 2, 29) do
              expect(user.age).to eq(20)
            end
          end
        end
      end

      describe '#adult?' do
        it 'returns true for adults' do
          user.date_of_birth = 25.years.ago.to_date
          expect(user).to be_valid
        end

        it 'returns false for users under 18' do
          user.date_of_birth = 16.years.ago.to_date
          expect(user).to be_valid
        end

        it 'returns true for 18 years' do
          user.date_of_birth = 18.years.ago.to_date
          expect(user).to be_valid
        end
      end
    end

    describe 'associations' do
      let(:user) { create(:user) }
      let(:list) { create(:list, user_id: user.id) }

      it 'has many items lists' do
        association = described_class.reflect_on_association(:lists)
        expect(association.macro).to eq(:has_many)
      end

      it "has dependent destroy on lists" do
        expect { user.destroy }.to change { List.count }.by(-user.lists.count)
      end
    end

    describe 'scopes' do
      # Add scope tests here if you have any scopes in the future
    end
  end
end
