require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_length_of(:first_name).is_at_most(100) }
    it { should validate_length_of(:last_name).is_at_most(100) }
  end

  describe "associations" do
    it { should belong_to(:department).optional }
    it { should belong_to(:manager).optional }
    it { should have_many(:direct_reports).dependent(:nullify) }
    it { should have_many(:time_off_requests).dependent(:destroy) }
  end

  describe "roles" do
    it "defaults to employee" do
      user = create(:user)
      expect(user).to be_employee
    end

    it "can be set to manager" do
      user = create(:user, :manager)
      expect(user).to be_manager
    end

    it "can be set to admin" do
      user = create(:user, :admin)
      expect(user).to be_admin
    end
  end

  describe "#full_name" do
    it "returns first and last name" do
      user = build(:user, first_name: "Jane", last_name: "Doe")
      expect(user.full_name).to eq("Jane Doe")
    end
  end

  describe "scopes" do
    it ".by_name orders by last name then first name" do
      bob   = create(:user, last_name: "Zeta", first_name: "Bob")
      alice = create(:user, last_name: "Alpha", first_name: "Alice")
      expect(User.by_name.first).to eq(alice)
    end
  end
end
