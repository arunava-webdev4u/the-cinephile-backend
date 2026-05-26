require 'rails_helper'

RSpec.describe "Api::V1::UserController", type: :request do
  let(:auth_token) { "sample-valid-token" }
  let(:user) { FactoryBot.create(:user) }
  let(:other_user) { FactoryBot.create(:user) }
  let(:decoded_token) { { user_id: user.id, jti: user.jti } }
  let(:headers) { { "Authorization" => "Bearer #{auth_token}", "CONTENT_TYPE" => "application/json" } }

  before do
    allow(Auth::JsonWebToken).to receive(:decode).and_return(decoded_token)
  end

  describe "Authentication" do
    it "returns unauthorized if token is missing" do
      get "/api/v1/user", headers: { "CONTENT_TYPE" => "application/json" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns unauthorized if token is invalid" do
      allow(Auth::JsonWebToken).to receive(:decode).and_return(nil)
      get "/api/v1/user", headers: headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/user" do
#     context "when user exists" do
#       it "returns the user profile" do
#         get "/api/v1/user", headers: headers

#         expect(response).to have_http_status(:ok)
#         parsed_response = JSON.parse(response.body)
#         expect(parsed_response["id"]).to eq(user.id)
#       end

#       it "returns user with necessary fields" do
#         get "/api/v1/user", headers: headers

#         parsed_response = JSON.parse(response.body)
#         expect(parsed_response).to include(
#           "id", "email", "first_name", "last_name", 
#           "date_of_birth", "country", "created_at", "updated_at"
#         )
#       end

#       it "includes user email" do
#         get "/api/v1/user", headers: headers

#         parsed_response = JSON.parse(response.body)
#         expect(parsed_response["email"]).to eq(user.email)
#       end

#       it "includes user name fields" do
#         get "/api/v1/user", headers: headers

#         parsed_response = JSON.parse(response.body)
#         expect(parsed_response["first_name"]).to eq(user.first_name)
#         expect(parsed_response["last_name"]).to eq(user.last_name)
#       end

#       it "includes user date of birth" do
#         get "/api/v1/user", headers: headers

#         parsed_response = JSON.parse(response.body)
#         expect(parsed_response["date_of_birth"]).to eq(user.date_of_birth.as_json)
#       end

#       it "includes user country" do
#         get "/api/v1/user", headers: headers

#         parsed_response = JSON.parse(response.body)
#         expect(parsed_response["country"]).to eq(user.country)
#       end
#     end

#     context "when user does not exist" do
#       before do
#         allow(Auth::JsonWebToken).to receive(:decode).and_return({ user_id: 99999, jti: "fake-jti" })
#       end

#       it "returns not found error" do
#         get "/api/v1/user", headers: headers

#         expect(response).to have_http_status(:not_found)
#       end
#     end
  end

#   describe "PUT /api/v1/user" do
#     let(:valid_params) do
#       {
#         user: {
#           first_name: "Updated",
#           last_name: "Name",
#           date_of_birth: "1995-05-15",
#           country: 1
#         }
#       }
#     end

#     let(:partial_update_params) do
#       {
#         user: { first_name: "John" }
#       }
#     end

#     let(:invalid_params) do
#       {
#         user: { first_name: "" }
#       }
#     end

#     context "with valid parameters" do
#       it "updates the user profile" do
#         put "/api/v1/user", params: valid_params.to_json, headers: headers

#         expect(response).to have_http_status(:ok)
#         parsed_response = JSON.parse(response.body)
#         expect(parsed_response["first_name"]).to eq("Updated")
#         expect(parsed_response["last_name"]).to eq("Name")
#       end

#       it "updates user in database" do
#         put "/api/v1/user", params: valid_params.to_json, headers: headers

#         user.reload
#         expect(user.first_name).to eq("Updated")
#         expect(user.last_name).to eq("Name")
#       end

#       it "allows partial updates" do
#         original_last_name = user.last_name
#         put "/api/v1/user", params: partial_update_params.to_json, headers: headers

#         user.reload
#         expect(user.first_name).to eq("John")
#         expect(user.last_name).to eq(original_last_name)
#       end

#       it "allows updating only email" do
#         email_params = { user: { email: "newemail@example.com" } }
#         put "/api/v1/user", params: email_params.to_json, headers: headers

#         user.reload
#         expect(user.email).to eq("newemail@example.com")
#       end

#       it "allows updating date_of_birth" do
#         dob_params = { user: { date_of_birth: "2000-01-01" } }
#         put "/api/v1/user", params: dob_params.to_json, headers: headers

#         user.reload
#         expect(user.date_of_birth.to_s).to eq("2000-01-01")
#       end

#       it "allows updating country" do
#         country_params = { user: { country: 42 } }
#         put "/api/v1/user", params: country_params.to_json, headers: headers

#         user.reload
#         expect(user.country).to eq(42)
#       end
#     end

#     context "with invalid parameters" do
#       it "returns unprocessable entity" do
#         put "/api/v1/user", params: invalid_params.to_json, headers: headers

#         expect(response).to have_http_status(:unprocessable_entity)
#       end

#       it "returns error details" do
#         put "/api/v1/user", params: invalid_params.to_json, headers: headers

#         parsed_response = JSON.parse(response.body)
#         expect(parsed_response).to include("error")
#       end

#       it "does not update the user when validation fails" do
#         original_first_name = user.first_name
#         put "/api/v1/user", params: invalid_params.to_json, headers: headers

#         user.reload
#         expect(user.first_name).to eq(original_first_name)
#       end
#     end

#     context "when user does not exist" do
#       before do
#         allow(Auth::JsonWebToken).to receive(:decode).and_return({ user_id: 99999, jti: "fake-jti" })
#       end

#       it "returns not found error" do
#         put "/api/v1/user", params: valid_params.to_json, headers: headers

#         expect(response).to have_http_status(:not_found)
#       end
#     end

#     context "with protected fields" do
#       it "should not allow updating password (if attempted)" do
#         password_params = { user: { password: "newpassword123" } }
#         put "/api/v1/user", params: password_params.to_json, headers: headers

#         # Password should not be updated (it's not in permitted params)
#         expect {
#           user.reload.authenticate("newpassword123")
#         }.to raise_error(NoMethodError)
#       end
#     end
#   end

#   describe "DELETE /api/v1/user" do
#     context "when user exists" do
#       it "deletes the user account" do
#         user_id = user.id
#         expect {
#           delete "/api/v1/user", headers: headers
#         }.to change(User, :count).by(-1)

#         expect(User.find_by(id: user_id)).to be_nil
#       end

#       it "returns success message" do
#         delete "/api/v1/user", headers: headers

#         expect(response).to have_http_status(:ok)
#         parsed_response = JSON.parse(response.body)
#         expect(parsed_response["message"]).to eq("User deleted successfully")
#       end

#       it "deletes associated lists and list items" do
#         # Create some lists and items for the user
#         custom_list = FactoryBot.create(:custom_list, user_id: user.id)
#         list_item = FactoryBot.create(:list_item, list_id: custom_list.id)

#         user_id = user.id
#         list_id = custom_list.id

#         delete "/api/v1/user", headers: headers

#         expect(User.find_by(id: user_id)).to be_nil
#         expect(List.find_by(id: list_id)).to be_nil
#         expect(ListItem.find_by(id: list_item.id)).to be_nil
#       end
#     end

#     context "when user does not exist" do
#       before do
#         allow(Auth::JsonWebToken).to receive(:decode).and_return({ user_id: 99999, jti: "fake-jti" })
#       end

#       it "returns not found error" do
#         delete "/api/v1/user", headers: headers

#         expect(response).to have_http_status(:not_found)
#       end

#       it "does not change user count" do
#         expect {
#           delete "/api/v1/user", headers: headers
#         }.not_to change(User, :count)
#       end
#     end
#   end

#   context "Authorization and Security Concerns" do
#     describe "accessing other user's profile" do
#       it "allows current user to view their own profile" do
#         get "/api/v1/user", headers: headers

#         expect(response).to have_http_status(:ok)
#         parsed_response = JSON.parse(response.body)
#         expect(parsed_response["id"]).to eq(user.id)
#       end

#       # BUG: Since the new resource :user route doesn't take an ID,
#       # it will always return the current user's profile
#       # But the old implementation could access any user by ID
#       it "with resource :user route, cannot access other user's profile (by design)" do
#         # With singular resource, this endpoint won't exist
#         # The route is /api/v1/user, not /api/v1/user/:id
#         # So this test documents that the security issue is resolved by the new routing
        
#         other_user_headers = { 
#           "Authorization" => "Bearer #{auth_token}", 
#           "CONTENT_TYPE" => "application/json" 
#         }
#         allow(Auth::JsonWebToken).to receive(:decode).and_return({ user_id: other_user.id, jti: other_user.jti })

#         get "/api/v1/user", headers: other_user_headers

#         expect(response).to have_http_status(:ok)
#         parsed_response = JSON.parse(response.body)
#         expect(parsed_response["id"]).to eq(other_user.id)
#       end
#     end

#     describe "updating other user's profile" do
#       it "can only update current user's profile" do
#         update_params = { user: { first_name: "Hacked" } }
#         other_user_headers = { 
#           "Authorization" => "Bearer #{auth_token}", 
#           "CONTENT_TYPE" => "application/json" 
#         }
#         allow(Auth::JsonWebToken).to receive(:decode).and_return({ user_id: other_user.id, jti: other_user.jti })

#         put "/api/v1/user", params: update_params.to_json, headers: other_user_headers

#         other_user.reload
#         expect(other_user.first_name).to eq("Hacked")
        
#         user.reload
#         expect(user.first_name).not_to eq("Hacked")
#       end
#     end

#     describe "deleting other user's profile" do
#       it "can only delete current user's account" do
#         user_first_name = user.first_name
#         other_user_id = other_user.id

#         other_user_headers = { 
#           "Authorization" => "Bearer #{auth_token}", 
#           "CONTENT_TYPE" => "application/json" 
#         }
#         allow(Auth::JsonWebToken).to receive(:decode).and_return({ user_id: other_user.id, jti: other_user.jti })

#         delete "/api/v1/user", headers: other_user_headers

#         expect(User.find_by(id: other_user_id)).to be_nil
#         user.reload
#         expect(user.first_name).to eq(user_first_name)
#       end
#     end
#   end

#   context "Edge Cases" do
#     describe "with special characters in name" do
#       it "allows special characters in names" do
#         special_params = { user: { first_name: "José", last_name: "García-López" } }
#         put "/api/v1/user", params: special_params.to_json, headers: headers

#         expect(response).to have_http_status(:ok)
#         user.reload
#         expect(user.first_name).to eq("José")
#       end
#     end

#     describe "with very long strings" do
#       it "handles long first_name gracefully" do
#         long_name = "A" * 500
#         long_params = { user: { first_name: long_name } }
#         put "/api/v1/user", params: long_params.to_json, headers: headers

#         # Should either succeed or return validation error
#         expect([200, 422]).to include(response.status)
#       end
#     end

#     describe "with null/empty values" do
#       it "rejects empty first_name" do
#         empty_params = { user: { first_name: "" } }
#         put "/api/v1/user", params: empty_params.to_json, headers: headers

#         expect(response).to have_http_status(:unprocessable_entity)
#       end

#       it "rejects null date_of_birth" do
#         null_params = { user: { date_of_birth: nil } }
#         put "/api/v1/user", params: null_params.to_json, headers: headers

#         # Should reject or allow depending on validation rules
#         expect([200, 422]).to include(response.status)
#       end
#     end

#     describe "duplicate email" do
#       it "prevents updating to another user's email (if email must be unique)" do
#         duplicate_email_params = { user: { email: other_user.email } }
#         put "/api/v1/user", params: duplicate_email_params.to_json, headers: headers

#         # Response depends on whether email uniqueness is enforced
#         if response.status == 422
#           parsed_response = JSON.parse(response.body)
#           expect(parsed_response).to include("error")
#         else
#           # If allowed, user should have the duplicate email
#           user.reload
#           expect(user.email).to eq(other_user.email)
#         end
#       end
#     end
#   end
end
