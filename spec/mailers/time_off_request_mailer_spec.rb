require "rails_helper"

RSpec.describe TimeOffRequestMailer, type: :mailer do
  let(:manager)  { create(:user, :manager, first_name: "Bob", last_name: "Smith") }
  let(:employee) { create(:user, manager: manager, first_name: "Jane", last_name: "Doe") }
  let(:request)  { create(:time_off_request, user: employee, leave_type: :vacation) }

  describe "#request_submitted" do
    it "sends to manager with employee name in subject" do
      mail = described_class.request_submitted(request)
      expect(mail.to).to include(manager.email)
      expect(mail.subject).to include(employee.full_name)
    end

    it "returns nil when employee has no manager" do
      employee.update!(manager: nil)
      mail = described_class.request_submitted(request)
      expect(mail.message).to be_a(ActionMailer::Base::NullMail)
    end
  end

  describe "#request_approved" do
    it "sends approval notice to employee" do
      mail = described_class.request_approved(request)
      expect(mail.to).to include(employee.email)
      expect(mail.subject).to include("approved")
    end
  end

  describe "#request_denied" do
    it "sends denial notice to employee" do
      mail = described_class.request_denied(request)
      expect(mail.to).to include(employee.email)
      expect(mail.subject).to include("denied")
    end
  end

  describe "#request_cancelled" do
    it "sends cancellation notice to employee" do
      mail = described_class.request_cancelled(request)
      expect(mail.to).to include(employee.email)
      expect(mail.subject).to include("cancelled")
    end
  end
end
