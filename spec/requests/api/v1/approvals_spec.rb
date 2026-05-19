require "rails_helper"

RSpec.describe "Api::V1::Approvals", type: :request do
  let(:admin)    { create(:user, :admin) }
  let(:manager)  { create(:user, :manager) }
  let(:employee) { create(:user, manager: manager) }
  let(:headers)  { { "CONTENT_TYPE" => "application/json" } }

  let!(:approved_request) do
    req = create(:time_off_request, :approved, user: employee)
    create(:approval, time_off_request: req, approver: manager, decision: :approved)
    req
  end

  describe "GET /api/v1/approvals" do
    context "as admin" do
      before { sign_in admin }

      it "returns all approvals" do
        get "/api/v1/approvals", headers: headers
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["data"].length).to eq(1)
      end
    end

    context "unauthenticated" do
      it "returns 401" do
        get "/api/v1/approvals", headers: headers
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/v1/approvals/:id" do
    let(:approval) { approved_request.approval }

    context "as admin" do
      before { sign_in admin }

      it "returns the approval" do
        get "/api/v1/approvals/#{approval.id}", headers: headers
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json.dig("data", "attributes", "decision")).to eq("approved")
      end
    end

    context "as employee (not owner)" do
      let(:other_employee) { create(:user) }
      before { sign_in other_employee }

      it "returns 403" do
        get "/api/v1/approvals/#{approval.id}", headers: headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
