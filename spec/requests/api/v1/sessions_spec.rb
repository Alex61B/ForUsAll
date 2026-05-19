require "rails_helper"

RSpec.describe "Api::V1::Sessions", type: :request do
  let(:user) { create(:user) }
  let(:headers) { { "CONTENT_TYPE" => "application/json" } }

  describe "POST /api/v1/auth/sign_in" do
    context "with valid credentials" do
      it "returns 200 with user data" do
        post "/api/v1/auth/sign_in", params: { user: { email: user.email, password: "password123" } }.to_json, headers: headers
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json.dig("data", "attributes", "email")).to eq(user.email)
      end
    end

    context "with invalid credentials" do
      it "returns 401" do
        post "/api/v1/auth/sign_in", params: { user: { email: user.email, password: "wrong" } }.to_json, headers: headers
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["errors"].first["title"]).to eq("Unauthorized")
      end
    end

    context "with unknown email" do
      it "returns 401" do
        post "/api/v1/auth/sign_in", params: { user: { email: "nobody@example.com", password: "password123" } }.to_json, headers: headers
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE /api/v1/auth/sign_out" do
    it "signs out and returns 200" do
      sign_in user
      delete "/api/v1/auth/sign_out", headers: headers
      expect(response).to have_http_status(:ok)
    end
  end
end
