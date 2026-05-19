require "rails_helper"

RSpec.describe UserPolicy, type: :policy do
  let(:admin)    { create(:user, :admin) }
  let(:employee) { create(:user) }
  let(:other)    { create(:user) }

  subject { described_class }

  describe "index?" do
    it "allows admin" do
      expect(subject.new(admin, User)).to be_index
    end

    it "denies employee" do
      expect(subject.new(employee, User)).not_to be_index
    end
  end

  describe "show?" do
    it "allows the user to view themselves" do
      expect(subject.new(employee, employee)).to be_show
    end

    it "allows admin to view anyone" do
      expect(subject.new(admin, other)).to be_show
    end

    it "denies employee viewing another user" do
      expect(subject.new(employee, other)).not_to be_show
    end
  end

  describe "update?" do
    it "allows the user to update themselves" do
      expect(subject.new(employee, employee)).to be_update
    end

    it "allows admin to update anyone" do
      expect(subject.new(admin, other)).to be_update
    end

    it "denies employee updating another user" do
      expect(subject.new(employee, other)).not_to be_update
    end
  end

  describe "Scope" do
    it "returns only self for employee" do
      scope = described_class::Scope.new(employee, User).resolve
      expect(scope).to include(employee)
      expect(scope).not_to include(other)
    end

    it "returns all for admin" do
      scope = described_class::Scope.new(admin, User).resolve
      expect(scope).to include(employee, other)
    end
  end
end
