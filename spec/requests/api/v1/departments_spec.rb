require "rails_helper"

RSpec.describe "Api::V1::Departments", type: :request do
  let(:admin)    { create(:user, :admin) }
  let(:employee) { create(:user) }
  let(:headers)  { { "CONTENT_TYPE" => "application/json" } }

  describe "GET /api/v1/departments" do
    before { create_list(:department, 3) }

    context "as authenticated user" do
      before { sign_in employee }

      it "returns departments in alphabetical order" do
        get "/api/v1/departments", headers: headers
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["data"].length).to eq(3)
        names = json["data"].map { |d| d.dig("attributes", "name") }
        expect(names).to eq(names.sort)
      end
    end

    context "unauthenticated" do
      it "returns 401" do
        get "/api/v1/departments", headers: headers
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/v1/departments/:id" do
    let(:dept) { create(:department) }

    context "as authenticated user" do
      before { sign_in employee }

      it "returns the department" do
        get "/api/v1/departments/#{dept.id}", headers: headers
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json.dig("data", "attributes", "name")).to eq(dept.name)
      end
    end

    it "returns 404 for missing department" do
      sign_in employee
      get "/api/v1/departments/999999", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
