class Department < ApplicationRecord
  has_many :users, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }

  scope :ordered, -> { order(:name) }
end
