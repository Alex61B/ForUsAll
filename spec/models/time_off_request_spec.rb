require "rails_helper"

RSpec.describe TimeOffRequest, type: :model do
  describe "validations" do
    it { should validate_presence_of(:leave_type) }
    it { should validate_presence_of(:start_date) }
    it { should validate_presence_of(:end_date) }
    it { should belong_to(:user) }
  end

  describe "business rules" do
    let(:employee) { create(:user) }

    describe "no past start dates" do
      it "is invalid when start_date is in the past" do
        req = build(:time_off_request, user: employee, start_date: Date.current - 1, end_date: Date.current)
        expect(req).not_to be_valid
        expect(req.errors[:start_date]).to include("cannot be in the past")
      end

      it "is valid when start_date is today" do
        req = build(:time_off_request, user: employee, start_date: Date.current, end_date: Date.current)
        expect(req).to be_valid
      end
    end

    describe "end date on or after start date" do
      it "is invalid when end_date before start_date" do
        req = build(:time_off_request, user: employee, start_date: Date.today + 5, end_date: Date.today + 3)
        expect(req).not_to be_valid
        expect(req.errors[:end_date]).to include("must be on or after start date")
      end
    end

    describe "overlapping requests" do
      let!(:existing) { create(:time_off_request, user: employee, start_date: Date.today + 10, end_date: Date.today + 15) }

      it "blocks overlapping pending request" do
        overlapping = build(:time_off_request, user: employee, start_date: Date.today + 12, end_date: Date.today + 18)
        expect(overlapping).not_to be_valid
        expect(overlapping.errors[:base]).to include("You already have a request for overlapping dates")
      end

      it "does not block non-overlapping request" do
        non_overlapping = build(:time_off_request, user: employee, start_date: Date.today + 20, end_date: Date.today + 22)
        expect(non_overlapping).to be_valid
      end

      it "allows denied requests to overlap" do
        existing.update_columns(status: 2)
        new_req = build(:time_off_request, user: employee, start_date: Date.today + 12, end_date: Date.today + 14)
        expect(new_req).to be_valid
      end
    end

    describe "annual vacation limit" do
      it "blocks requests exceeding #{TimeOffRequest::ANNUAL_VACATION_LIMIT} vacation days" do
        create(:time_off_request, user: employee,
               start_date: Date.today + 20,
               end_date:   Date.today + 33,
               leave_type: :vacation)
        over_limit = build(:time_off_request, user: employee,
                           start_date: Date.today + 40,
                           end_date:   Date.today + 43,
                           leave_type: :vacation)
        expect(over_limit).not_to be_valid
        expect(over_limit.errors[:base].first).to include("annual vacation limit")
      end

      it "does not apply annual limit to sick leave" do
        create(:time_off_request, user: employee,
               start_date: Date.today + 20,
               end_date:   Date.today + 40,
               leave_type: :sick)
        sick_req = build(:time_off_request, user: employee,
                         start_date: Date.today + 50,
                         end_date:   Date.today + 60,
                         leave_type: :sick)
        expect(sick_req).to be_valid
      end
    end
  end

  describe "#duration_days" do
    it "calculates inclusive day count" do
      req = build(:time_off_request, start_date: Date.today + 1, end_date: Date.today + 3)
      expect(req.duration_days).to eq(3)
    end

    it "returns 1 for same-day request" do
      req = build(:time_off_request, start_date: Date.today + 1, end_date: Date.today + 1)
      expect(req.duration_days).to eq(1)
    end
  end

  describe "scopes" do
    let(:employee) { create(:user) }
    let(:manager)  { create(:user, :manager) }

    it ".visible_to returns only own requests for employee" do
      own     = create(:time_off_request, user: employee)
      other   = create(:time_off_request)
      expect(TimeOffRequest.visible_to(employee)).to include(own)
      expect(TimeOffRequest.visible_to(employee)).not_to include(other)
    end

    it ".visible_to returns direct reports' requests for manager" do
      report  = create(:user, manager: manager)
      report_req = create(:time_off_request, user: report)
      other_req  = create(:time_off_request)
      expect(TimeOffRequest.visible_to(manager)).to include(report_req)
      expect(TimeOffRequest.visible_to(manager)).not_to include(other_req)
    end

    it ".visible_to returns all for admin" do
      admin = create(:user, :admin)
      req1 = create(:time_off_request)
      req2 = create(:time_off_request)
      expect(TimeOffRequest.visible_to(admin)).to include(req1, req2)
    end
  end
end
