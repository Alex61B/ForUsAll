require "rails_helper"

RSpec.describe "Api::V1::Users", type: :request do
  let(:admin)    { create(:user, :admin) }
  let(:manager)  { create(:user, :manager) }
  let(:employee) { create(:user) }
  let(:headers)  { { "CONTENT_TYPE" => "application/json" } }

  describe "GET /api/v1/users" do
    context "as admin" do
      before { sign_in admin }

      it "returns all users" do
        create_list(:user, 3)
        get "/api/v1/users", headers: headers
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["data"].length).to be >= 4
      end
    end

    context "unauthenticated" do
      it "returns 401" do
        get "/api/v1/users", headers: headers
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/v1/users/:id" do
    context "as the user themselves" do
      before { sign_in employee }

      it "returns their profile" do
        get "/api/v1/users/#{employee.id}", headers: headers
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json.dig("data", "attributes", "email")).to eq(employee.email)
      end
    end

    context "as admin viewing any user" do
      before { sign_in admin }

      it "returns the user" do
        get "/api/v1/users/#{employee.id}", headers: headers
        expect(response).to have_http_status(:ok)
      end
    end

    context "as employee viewing another employee" do
      before { sign_in employee }

      it "returns 403" do
        other = create(:user)
        get "/api/v1/users/#{other.id}", headers: headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "PATCH /api/v1/users/:id" do
    context "as the user updating their own profile" do
      before { sign_in employee }

      it "updates first_name" do
        patch "/api/v1/users/#{employee.id}",
              params: { user: { first_name: "Updated" } }.to_json,
              headers: headers
        expect(response).to have_http_status(:ok)
        expect(employee.reload.first_name).to eq("Updated")
      end

      it "cannot change their own role" do
        patch "/api/v1/users/#{employee.id}",
              params: { user: { role: "admin" } }.to_json,
              headers: headers
        expect(employee.reload.role).to eq("employee")
      end
    end

    context "as admin" do
      before { sign_in admin }

      it "can change a user's role" do
        patch "/api/v1/users/#{employee.id}",
              params: { user: { role: "manager" } }.to_json,
              headers: headers
        expect(response).to have_http_status(:ok)
        expect(employee.reload.role).to eq("manager")
      end
    end
  end
end
