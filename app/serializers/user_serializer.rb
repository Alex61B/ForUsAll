class UserSerializer
  include JSONAPI::Serializer
  attributes :email, :first_name, :last_name, :full_name, :role, :created_at

  belongs_to :department, serializer: DepartmentSerializer
end
