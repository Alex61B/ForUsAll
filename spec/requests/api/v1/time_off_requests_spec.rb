require "rails_helper"

RSpec.describe "Api::V1::TimeOffRequests", type: :request do
  let(:admin)    { create(:user, :admin) }
  let(:manager)  { create(:user, :manager) }
  let(:employee) { create(:user, manager: manager) }
  let(:headers)  { { "CONTENT_TYPE" => "application/json" } }

  describe "GET /api/v1/time_off_requests" do
    before do
      create(:time_off_request, user: employee)
      create(:time_off_request)
    end

    context "as employee" do
      before { sign_in employee }

      it "returns only their own requests" do
        get "/api/v1/time_off_requests", headers: headers
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        user_ids = json["data"].map { |r| r.dig("relationships", "user", "data", "id") }
        expect(user_ids).to all(eq(employee.id.to_s))
      end
    end

    context "as manager" do
      before { sign_in manager }

      it "returns direct reports' requests" do
        get "/api/v1/time_off_requests", headers: headers
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["data"].length).to eq(1)
      end
    end

    context "as admin" do
      before { sign_in admin }

      it "returns all requests" do
        get "/api/v1/time_off_requests", headers: headers
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["data"].length).to eq(2)
      end
    end
  end

  describe "POST /api/v1/time_off_requests" do
    before { sign_in employee }

    let(:valid_params) do
      {
        time_off_request: {
          leave_type: "vacation",
          start_date: (Date.current + 10).iso8601,
          end_date:   (Date.current + 12).iso8601,
          reason:     "Holiday"
        }
      }.to_json
    end

    it "creates a request and enqueues manager notification" do
      expect {
        post "/api/v1/time_off_requests", params: valid_params, headers: headers
      }.to have_enqueued_job(NotifyManagerJob)
      expect(response).to have_http_status(:created)
    end

    it "returns 422 for invalid dates" do
      params = { time_off_request: { leave_type: "vacation", start_date: (Date.current - 1).iso8601, end_date: Date.current.iso8601 } }.to_json
      post "/api/v1/time_off_requests", params: params, headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /api/v1/time_off_requests/:id" do
    let(:request) { create(:time_off_request, user: employee) }
    before { sign_in employee }

    it "updates a pending request" do
      patch "/api/v1/time_off_requests/#{request.id}",
            params: { time_off_request: { reason: "Updated reason" } }.to_json,
            headers: headers
      expect(response).to have_http_status(:ok)
      expect(request.reload.reason).to eq("Updated reason")
    end

    it "cannot update an approved request" do
      approved = create(:time_off_request, :approved, user: employee)
      patch "/api/v1/time_off_requests/#{approved.id}",
            params: { time_off_request: { reason: "Too late" } }.to_json,
            headers: headers
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /api/v1/time_off_requests/:id/approve" do
    let(:pending_req) { create(:time_off_request, user: employee) }

    context "as manager of the requester" do
      before { sign_in manager }

      it "approves and enqueues notification" do
        expect {
          patch "/api/v1/time_off_requests/#{pending_req.id}/approve", headers: headers
        }.to have_enqueued_job(NotifyRequesterJob)
        expect(response).to have_http_status(:ok)
        expect(pending_req.reload.status).to eq("approved")
      end
    end

    context "as unrelated manager" do
      let(:other_manager) { create(:user, :manager) }
      before { sign_in other_manager }

      it "returns 403" do
        patch "/api/v1/time_off_requests/#{pending_req.id}/approve", headers: headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "PATCH /api/v1/time_off_requests/:id/deny" do
    let(:pending_req) { create(:time_off_request, user: employee) }
    before { sign_in manager }

    it "denies and enqueues notification" do
      expect {
        patch "/api/v1/time_off_requests/#{pending_req.id}/deny", headers: headers
      }.to have_enqueued_job(NotifyRequesterJob)
      expect(response).to have_http_status(:ok)
      expect(pending_req.reload.status).to eq("denied")
    end
  end

  describe "DELETE /api/v1/time_off_requests/:id" do
    let(:pending_req) { create(:time_off_request, user: employee) }
    before { sign_in employee }

    it "cancels the request" do
      delete "/api/v1/time_off_requests/#{pending_req.id}", headers: headers
      expect(response).to have_http_status(:no_content)
      expect(pending_req.reload.status).to eq("cancelled")
    end
  end
end
