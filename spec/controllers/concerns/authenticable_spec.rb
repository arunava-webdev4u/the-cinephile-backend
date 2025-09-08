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

        context "when Authorization header is present but invalid format" do
            it "returns unauthorized" do
                request.headers["Authorization"] = "InvalidTokenFormat"
                get :index

                expect(response).to have_http_status(:unauthorized)
                expect(JSON.parse(response.body)["error"]).to eq("Authorization token is missing")
            end
        end
        
        context "when token is invalid or expired" do
            before do
                allow(Auth::JsonWebToken).to receive(:decode).and_return(nil)
            end

            it "returns unauthorized" do
                request.headers["Authorization"] = "Bearer invalid-or-expired-token"
                get :index

                expect(response).to have_http_status(:unauthorized)
                expect(JSON.parse(response.body)["error"]).to eq("Invalid or expired token")
            end
        end

        context "when decoded token does not match any user" do
            before do
                allow(User).to receive(:find_by).and_return(nil)
            end

            it "returns unauthorized" do
                request.headers["Authorization"] = "Bearer #{token}"
                get :index

                expect(response).to have_http_status(:unauthorized)
                expect(JSON.parse(response.body)["error"]).to eq("Invalid or expired token")
            end
        end

        context "when decoded token jti does not match user jti" do
            before do
                allow(Auth::JsonWebToken).to receive(:decode).and_return({ user_id: user.id, jti: "different-jti" })
            end

            it "returns unauthorized" do
                request.headers["Authorization"] = "Bearer #{token}"
                get :index

                expect(response).to have_http_status(:unauthorized)
                expect(JSON.parse(response.body)["error"]).to eq("Invalid or expired token")
            end
        end
        
        context "when token is valid" do
            before do
                allow(Auth::JsonWebToken).to receive(:decode).and_return({ user_id: user.id, jti: user.jti })
            end

            it "sets @current_user and allows access" do
                request.headers["Authorization"] = "Bearer #{token}"
                get :index
                
                expect(response).to have_http_status(:ok)
                expect(JSON.parse(response.body)).to eq({ "message" => "success" })
                expect(controller.instance_variable_get(:@current_user)).to eq(user)
            end
        end
    end
end
