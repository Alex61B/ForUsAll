class Api::V1::DepartmentsController < Api::V1::BaseController
  before_action :set_department, only: [ :show ]

  def index
    departments = policy_scope(Department).ordered
    render_jsonapi(DepartmentSerializer, departments)
  end

  def show
    authorize @department
    render_jsonapi(DepartmentSerializer, @department)
  end

  private

  def set_department
    @department = Department.find(params[:id])
  end
end
