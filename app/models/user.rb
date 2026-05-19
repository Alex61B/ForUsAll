class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  enum :role, { employee: 0, manager: 1, admin: 2 }, validate: true

  belongs_to :department, optional: true
  belongs_to :manager, class_name: "User", optional: true
  has_many :direct_reports, class_name: "User", foreign_key: :manager_id, dependent: :nullify, inverse_of: :manager
  has_many :time_off_requests, dependent: :destroy
  has_many :given_approvals, class_name: "Approval", foreign_key: :approver_id, dependent: :nullify

  validates :first_name, presence: true, length: { maximum: 100 }
  validates :last_name, presence: true, length: { maximum: 100 }
  validates :role, presence: true

  scope :by_name, -> { order(:last_name, :first_name) }

  def full_name
    "#{first_name} #{last_name}"
  end
end
