require 'rails_helper'

RSpec.describe User, type: :model do
  let(:valid_attributes) do
    {
      first_name: 'John',
      last_name: 'Doe',
      email: 'john.doe@gmail.com',
      password: '1234',
      date_of_birth: Date.new(1990, 12, 28),
      country: 4
    }
  end

  context 'validations' do
    it 'is valid with valid attributes' do
      user = User.new(valid_attributes)
      expect(user).to be_valid
    end

    context 'first_name validations' do
      it 'can not be empty' do
        user = User.new(valid_attributes.merge(first_name: nil))
        expect(user).not_to be_valid
        expect(user.errors[:first_name]).to include("can't be blank")
      end

      it 'must contain only alphabets' do
        user = User.new(valid_attributes.merge(first_name: 'John123'))
        expect(user).not_to be_valid
        expect(user.errors[:first_name]).to include('must contain only alphabets')
      end
    end

    context 'last_name validations' do
      it 'can not be empty' do
        user = User.new(valid_attributes.merge(last_name: nil))
        expect(user).not_to be_valid
        expect(user.errors[:last_name]).to include("can't be blank")
      end

      it 'must contain only alphabets' do
        user = User.new(valid_attributes.merge(last_name: 'Doe123'))
        expect(user).not_to be_valid
        expect(user.errors[:last_name]).to include('must contain only alphabets')
      end
    end

    context 'email validations' do
      it 'is not valid without an email' do
        user = User.new(valid_attributes.merge(email: nil))
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("can't be blank")
      end

      it 'is not valid with an invalid email format' do
        user = User.new(valid_attributes.merge(email: 'invalid-email'))
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include('is invalid')
      end

      it 'is not valid with a duplicate email' do
        User.create!(valid_attributes)
        user = User.new(valid_attributes)
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include('has already been taken')
      end

      # it 'must have a supported email domain' do
      #   user = User.new(valid_attributes.merge(email: 'arunava.das@example.com'))
      #   expect(user).not_to be_valid
      #   expect(user.errors[:email]).to include('domain is not supported')
      # end
    end

    context 'date_of_birth validations' do
      it 'is not valid without a date_of_birth' do
        user = User.new(valid_attributes.merge(date_of_birth: nil))
        expect(user).not_to be_valid
        expect(user.errors[:date_of_birth]).to include("can't be blank")
      end

      it 'date_of_birth must be a valid date' do
        user = User.new(valid_attributes.merge(date_of_birth: 'abcd-xy-00'))
        expect(user).not_to be_valid
      end

      it 'date_of_birth cant be a future date' do
        user = User.new(valid_attributes.merge(date_of_birth: Date.current + 1.day))
        expect(user).not_to be_valid
        expect(user.errors[:date_of_birth]).to include('can not be today or a future date')
      end
    end

    context 'country validations' do
      it 'must be present' do
        user = User.new(valid_attributes.merge(country: nil))
        expect(user).not_to be_valid
        expect(user.errors[:country]).to include("can't be blank")
      end

      it 'must be a number' do
        user = User.new(valid_attributes.merge(country: 'canada'))
        puts "-------------------"
        puts user.inspect
        puts user.valid?
        puts user.errors
        # expect(user.errors[:country]).to include('must contain only ')
        expect(user).not_to be_valid
      end

      # it 'must be in our country list' do
      #   user = User.new(valid_attributes.merge(country: 'Tiwan'))
      #   expect(user).not_to be_valid
      #   expect(user.errors[:country]).to include('is not in our country list')
      # end
    end

  context 'associations' do
    # Add association tests here if you have any associations in the future
  end

  context 'scopes' do
    # Add scope tests here if you have any scopes in the future
  end

  context 'methods' do
    # Add method tests here if you have any custom methods in the future
  end

  end
end
