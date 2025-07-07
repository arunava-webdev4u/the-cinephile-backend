require 'rails_helper'

RSpec.describe List, type: :model do

  describe 'validations' do
    it "is valid with valid attributes" do
      user = create(:user)
      custom_list = create(:custom_list, user_id: user.id)
    end
  end
  

end
