require 'rails_helper'

RSpec.describe Authenticable, type: :controller  do
    controller(Api::V1::ApplicationController) do
        include Authenticable
        
        def index
            render json: { message: "success" }
        end
    end

    let(:jti) { SecureRandom.uuid }
    let(:user) { create(:user, jti: jti) }
    let(:token) { Auth::JsonWebToken.encode(user_id: user.id, jti: jti) }

    before do
        path = controller.controller_path
        routes.draw { get "index" => "#{path}#index" }
    end

    describe "GET #index" do
        context "when Authorization header is missing" do
            it "returns unauthorized" do
                get :index

                expect(response).to have_http_status(:unauthorized)
                expect(JSON.parse(response.body)["error"]).to eq("Authorization token is missing")
            end
        end

        # context "when Authorization header is present but invalid format" do
            # it "returns unauthorized" do
        
        # context "when token is invalid or expired" do
        #     before do
        #     allow(Auth::JsonWebToken).to receive(:decode).and_return(nil)
        #   end
            #  it "returns unauthorized" do

        # context "when decoded token does not match any user" do
            # it "returns unauthorized" do
            
        #  context "when decoded token jti does not match user jti" do
            # it "returns unauthorized" do

        #  context "when token is valid" do
    end
end
