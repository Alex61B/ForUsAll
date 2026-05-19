class ApprovalSerializer
  include JSONAPI::Serializer
  attributes :decision, :notes, :created_at, :updated_at

  belongs_to :time_off_request
  belongs_to :approver, record_type: :user, serializer: UserSerializer
end
