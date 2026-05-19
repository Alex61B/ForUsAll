require "rails_helper"

RSpec.describe Department, type: :model do
  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(100) }

    it "validates uniqueness of name (case-insensitive)" do
      create(:department, name: "Engineering")
      dept = build(:department, name: "engineering")
      expect(dept).not_to be_valid
      expect(dept.errors[:name]).to include("has already been taken")
    end
  end

  describe "associations" do
    it { should have_many(:users).dependent(:restrict_with_error) }
  end

  describe "scopes" do
    it ".ordered returns departments alphabetically" do
      z_dept = create(:department, name: "Zzz")
      a_dept = create(:department, name: "Aaa")
      expect(Department.ordered.first).to eq(a_dept)
    end
  end

  describe "destruction" do
    it "cannot be destroyed when it has users" do
      dept = create(:department)
      create(:user, department: dept)
      expect(dept.destroy).to be_falsey
    end

    it "can be destroyed when empty" do
      dept = create(:department)
      expect { dept.destroy }.to change(Department, :count).by(-1)
    end
  end
end
