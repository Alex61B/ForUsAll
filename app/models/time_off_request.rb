class TimeOffRequest < ApplicationRecord
  ANNUAL_VACATION_LIMIT = 15

  enum :leave_type, { vacation: 0, sick: 1, personal: 2 }, validate: true
  enum :status, { pending: 0, approved: 1, denied: 2, cancelled: 3 }, validate: true

  belongs_to :user
  belongs_to :reviewed_by, class_name: "User", optional: true
  has_one :approval, dependent: :destroy

  validates :leave_type, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :reason, length: { maximum: 1000 }, allow_blank: true

  validate :start_date_not_in_past, if: -> { start_date.present? && new_record? }
  validate :end_date_on_or_after_start_date, if: -> { start_date.present? && end_date.present? }
  validate :no_overlapping_requests, if: -> { start_date.present? && end_date.present? && user_id.present? && active? }
  validate :within_annual_vacation_limit, if: -> { vacation? && start_date.present? && user_id.present? && active? }

  scope :visible_to, ->(user) {
    if user.admin?
      all
    elsif user.manager?
      where(user_id: [ user.id ] + user.direct_reports.pluck(:id))
    else
      where(user: user)
    end
  }
  scope :by_status, ->(s) { where(status: s) if s.present? }
  scope :by_leave_type, ->(t) { where(leave_type: t) if t.present? }
  scope :by_user, ->(uid) { where(user_id: uid) if uid.present? }

  def duration_days
    return 0 unless start_date && end_date
    (end_date - start_date).to_i + 1
  end

  private

  def active?
    !cancelled? && !denied?
  end

  def start_date_not_in_past
    errors.add(:start_date, "cannot be in the past") if start_date < Date.current
  end

  def end_date_on_or_after_start_date
    errors.add(:end_date, "must be on or after start date") if end_date < start_date
  end

  def no_overlapping_requests
    overlapping = user.time_off_requests
      .where(status: [ :pending, :approved ])
      .where("start_date <= ? AND end_date >= ?", end_date, start_date)
      .where.not(id: id)
    errors.add(:base, "You already have a request for overlapping dates") if overlapping.exists?
  end

  def within_annual_vacation_limit
    existing_days = user.time_off_requests
      .where(leave_type: :vacation, status: [ :pending, :approved ])
      .where("EXTRACT(year FROM start_date) = ?", start_date.year)
      .where.not(id: id)
      .sum("end_date - start_date + 1")
    if existing_days + duration_days > ANNUAL_VACATION_LIMIT
      errors.add(:base, "You have reached the annual vacation limit of #{ANNUAL_VACATION_LIMIT} days")
    end
  end
end
