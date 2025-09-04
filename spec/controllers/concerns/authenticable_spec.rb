require 'rails_helper'

RSpec.describe Authenticable, type: :concern  do
    let(:dummy_controller_class) do
        Class.new(ApplicationController) do
            include Authenticable
            
            def test_action
                render json: { message: 'success' }
            end
        end
    end
end
