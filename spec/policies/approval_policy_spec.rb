require "rails_helper"

RSpec.describe ApprovalPolicy, type: :policy do
  let(:admin)    { create(:user, :admin) }
  let(:manager)  { create(:user, :manager) }
  let(:employee) { create(:user, manager: manager) }
  let(:other)    { create(:user) }

  let(:request)  { create(:time_off_request, :approved, user: employee) }
  let(:approval) { create(:approval, time_off_request: request, approver: manager, decision: :approved) }

  subject { described_class }

  describe "index?" do
    it "allows admin" do
      expect(subject.new(admin, Approval)).to be_index
    end

    it "allows manager" do
      expect(subject.new(manager, Approval)).to be_index
    end

    it "denies employee" do
      expect(subject.new(employee, Approval)).not_to be_index
    end
  end

  describe "show?" do
    it "allows admin" do
      expect(subject.new(admin, approval)).to be_show
    end

    it "allows the employee whose request was approved" do
      expect(subject.new(employee, approval)).to be_show
    end

    it "allows the approving manager" do
      expect(subject.new(manager, approval)).to be_show
    end

    it "denies unrelated employee" do
      expect(subject.new(other, approval)).not_to be_show
    end
  end
end
