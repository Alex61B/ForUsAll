class Approval < ApplicationRecord
  enum :decision, { approved: 0, denied: 1 }, validate: true

  belongs_to :time_off_request
  belongs_to :approver, class_name: "User"

  validates :decision, presence: true
end
