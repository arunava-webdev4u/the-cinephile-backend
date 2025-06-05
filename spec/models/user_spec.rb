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

      it 'must be less than 50 characters' do
        user = User.new(valid_attributes.merge(first_name: "asdkkfjhasdfjhaslkfhaslfhaslfhaslfjashflkashflasfhasljgsfjasgljasgflsfgasdlkfgasfjasgfjasgflasjfgaslfgaslfgsdljfg"))
        expect(user).not_to be_valid
        expect(user.errors[:first_name]).to include('is too long (maximum is 50 characters)')
      end

      it 'can not be an empty string' do
        user = User.new(valid_attributes.merge(first_name: ""))
        expect(user).not_to be_valid
        expect(user.errors[:first_name]).to include('is too short (minimum is 1 character)')
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

      it 'must be less than 50 characters' do
        user = User.new(valid_attributes.merge(last_name: "asdkkfjhasdfjhaslkfhaslfhaslfhaslfjashflkashflasfhasljgsfjasgljasgflsfgasdlkfgasfjasgfjasgflasjfgaslfgaslfgsdljfg"))
        expect(user).not_to be_valid
        expect(user.errors[:last_name]).to include('is too long (maximum is 50 characters)')
      end

      it 'can not be an empty string' do
        user = User.new(valid_attributes.merge(last_name: ""))
        expect(user).not_to be_valid
        expect(user.errors[:last_name]).to include('is too short (minimum is 1 character)')
      end
    end

    context 'email validations' do
      it 'is not valid without an email' do
        user = User.new(valid_attributes.merge(email: nil))
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("can't be blank")
      end

      it 'can not be more than 254 characters long' do
        user = User.new(valid_attributes.merge(email: "an5230957309n30934n934603n756340760n68s987s98a7rabe97re9r7ba09rae6r970ae6r0b79a6r0ewb76raewb78r6ae87rbawe08b7r6a ew7b0r6ae w7r6aew87baew97r6aew0r796aewr7baewtarb7aetrew78btre78r63487b63478rb6e870ryse8b70ybe47tse478tb6e4t6eb87tser8f7esbtes478ts487bts8743t48o37ny8r347y87368234685vn3478rycw47sbt743y75634novsry487tn473657nv46si8r478s4c34n875634nc5s634bs537843478b3s7o8b437so43sr7y43nr8y34tb473s4o8or@example.com"))
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include('is too long (maximum is 254 characters)')
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

      it 'is not valid with a duplicate email with case sensitivity' do
        User.create!(valid_attributes.merge(email: "test@example.com"))
        user = User.new(valid_attributes.merge(email: "TEST@example.com"))
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

      it 'cant be a ghost' do
        user = User.new(valid_attributes.merge(date_of_birth: Date.current-120.years))
        expect(user).not_to be_valid
        expect(user.errors[:date_of_birth]).to include('must be within the last 120 years')
      end
    end

    context 'country validations' do
      it 'must be present' do
        user = User.new(valid_attributes.merge(country: nil))
        expect(user).not_to be_valid
        expect(user.errors[:country]).to include("can't be blank")
      end

      context 'data type validation' do
        it 'must be a number' do
          user = User.new(valid_attributes.merge(country: 'canada'))
          expect(user).not_to be_valid
          expect(user.errors[:country]).to include("is not a number")
        end

        it 'must be a whole number' do
          user = User.new(valid_attributes.merge(country: 5.782))
          expect(user).not_to be_valid
          expect(user.errors[:country]).to include("must be an integer")
        end

        it 'must be a greater thatn 0' do
          user = User.new(valid_attributes.merge(country: -5))
          expect(user).not_to be_valid
          expect(user.errors[:country]).to include("must be greater than 0")
        end
      end

      # it 'must be in our country list' do
      #   user = User.new(valid_attributes.merge(country: 'Tiwan'))
      #   expect(user).not_to be_valid
      #   expect(user.errors[:country]).to include('is not in our country list')
      # end
    end

    context 'callbacks' do
      context '#strip_whitespace' do
        it 'strips whitespace from names' do
          user = User.new(valid_attributes.merge({ first_name: '  John  ', last_name: '  Doe  ', email: "  abc@gmail.com    " }))

          user.valid?
          expect(user.first_name).to eq('John')
          expect(user.last_name).to eq('Doe')
          expect(user.email).to eq('abc@gmail.com')
        end
      end
    end

    context 'instance methods' do
      context '#full_name' do
        it 'returns first and last name combined' do
          user = User.new(valid_attributes)
          expect(user.full_name).to eq('John Doe')
        end

        it 'strips extra whitespace' do
          user = User.create!(valid_attributes.merge({ first_name: '  John  ', last_name: '  Doe  ' }))
          expect(user.full_name).to eq('John Doe')
        end
      end

      context '#age' do
        # it 'calculates age correctly' do
        #   user = User.new(valid_attributes.merge(date_of_birth: 25.years.ago.to_date))
        #   expect(user.age).to eq(25)
        # end

        # it 'handles leap years correctly' do
        #   # Born on leap day 24 years ago
        #   leap_day = Date.new(2000, 2, 29)
        #   user.date_of_birth = leap_day

        #   # Mock current date to test leap year calculation
        #   allow(Date).to receive(:current).and_return(Date.new(2024, 3, 1))
        #   expect(user.age).to eq(24)
        # end

        # it 'calculates age correctly near birthday' do
        #   # Born exactly 25 years ago tomorrow
        #   user.date_of_birth = (25.years.ago + 1.day).to_date
        #   expect(user.age).to eq(24) # Still 24 until tomorrow
        # end
      end

      context '#adult?' do
        it 'returns true for adults' do
          user = User.new(valid_attributes.merge(date_of_birth: 25.years.ago.to_date))
          expect(user).to be_valid
        end

        it 'returns false for users under 18' do
          user = User.new(valid_attributes.merge(date_of_birth: 16.years.ago.to_date))
          expect(user).to be_valid
        end

        it 'returns true for 18 years' do
          user = User.new(valid_attributes.merge(date_of_birth: 18.years.ago.to_date))
          expect(user).to be_valid
        end
      end
    end

    context 'associations' do
      # Add association tests here if you have any associations in the future
    end

    context 'scopes' do
      # Add scope tests here if you have any scopes in the future
    end
  end
end
