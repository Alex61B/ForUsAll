require "rails_helper"

RSpec.describe Approval, type: :model do
  describe "associations" do
    it { should belong_to(:time_off_request) }
    it { should belong_to(:approver).class_name("User") }
  end

  describe "validations" do
    it { should validate_presence_of(:decision) }
  end

  describe "decision enum" do
    it "has approved and denied decisions" do
      expect(Approval.decisions.keys).to match_array(%w[approved denied])
    end
  end
end
