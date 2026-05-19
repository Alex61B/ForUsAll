require "rails_helper"

RSpec.describe TimeOffRequestPolicy, type: :policy do
  let(:admin)    { create(:user, :admin) }
  let(:manager)  { create(:user, :manager) }
  let(:employee) { create(:user, manager: manager) }
  let(:other)    { create(:user) }

  let(:pending_request)  { create(:time_off_request, user: employee) }
  let(:approved_request) { create(:time_off_request, :approved, user: employee) }
  let(:denied_request)   { create(:time_off_request, :denied, user: employee) }

  subject { described_class }

  describe "show?" do
    it "allows the owner" do
      expect(subject.new(employee, pending_request)).to be_show
    end

    it "allows the manager of the owner" do
      expect(subject.new(manager, pending_request)).to be_show
    end

    it "allows admin" do
      expect(subject.new(admin, pending_request)).to be_show
    end

    it "denies unrelated employee" do
      expect(subject.new(other, pending_request)).not_to be_show
    end
  end

  describe "update?" do
    it "allows owner when pending" do
      expect(subject.new(employee, pending_request)).to be_update
    end

    it "denies owner when approved" do
      expect(subject.new(employee, approved_request)).not_to be_update
    end

    it "denies admin on approved (policy requires pending?)" do
      expect(subject.new(admin, approved_request)).not_to be_update
    end
  end

  describe "approve?" do
    it "allows manager of requester" do
      expect(subject.new(manager, pending_request)).to be_approve
    end

    it "allows admin" do
      expect(subject.new(admin, pending_request)).to be_approve
    end

    it "denies already-approved request" do
      expect(subject.new(manager, approved_request)).not_to be_approve
    end

    it "denies owner from self-approving" do
      expect(subject.new(employee, pending_request)).not_to be_approve
    end

    it "denies unrelated manager" do
      unrelated = create(:user, :manager)
      expect(subject.new(unrelated, pending_request)).not_to be_approve
    end
  end

  describe "deny?" do
    it "allows manager of requester" do
      expect(subject.new(manager, pending_request)).to be_deny
    end

    it "denies already-denied request" do
      expect(subject.new(manager, denied_request)).not_to be_deny
    end
  end

  describe "cancel?" do
    it "allows owner when pending" do
      expect(subject.new(employee, pending_request)).to be_cancel
    end

    it "allows manager when pending" do
      expect(subject.new(manager, pending_request)).to be_cancel
    end

    it "denies when not pending" do
      expect(subject.new(employee, approved_request)).not_to be_cancel
    end
  end

  describe "Scope" do
    it "returns own requests for employee" do
      pending_request
      other_req = create(:time_off_request, user: other)
      scope = described_class::Scope.new(employee, TimeOffRequest).resolve
      expect(scope).to include(pending_request)
      expect(scope).not_to include(other_req)
    end

    it "returns direct reports' requests for manager" do
      pending_request
      other_req = create(:time_off_request, user: other)
      scope = described_class::Scope.new(manager, TimeOffRequest).resolve
      expect(scope).to include(pending_request)
      expect(scope).not_to include(other_req)
    end

    it "returns all requests for admin" do
      pending_request
      other_req = create(:time_off_request, user: other)
      scope = described_class::Scope.new(admin, TimeOffRequest).resolve
      expect(scope).to include(pending_request, other_req)
    end
  end
end
