class TimeOffRequestSerializer
  include JSONAPI::Serializer
  attributes :leave_type, :start_date, :end_date, :reason, :status,
             :reviewed_at, :duration_days, :created_at, :updated_at

  belongs_to :user, serializer: UserSerializer
  belongs_to :reviewed_by, record_type: :user, serializer: UserSerializer
  has_one :approval, serializer: ApprovalSerializer
end
