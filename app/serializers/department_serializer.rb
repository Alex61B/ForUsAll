class DepartmentSerializer
  include JSONAPI::Serializer
  attributes :name, :created_at, :updated_at
end
