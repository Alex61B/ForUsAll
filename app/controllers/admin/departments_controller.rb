class Admin::DepartmentsController < Admin::BaseController
  before_action :set_department, only: [ :edit, :update, :destroy ]

  def index
    @departments = Department.ordered
  end

  def new
    @department = Department.new
  end

  def create
    @department = Department.new(department_params)
    if @department.save
      redirect_to admin_departments_path, notice: "Department created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @department.update(department_params)
      redirect_to admin_departments_path, notice: "Department updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @department.destroy
      redirect_to admin_departments_path, notice: "Department deleted."
    else
      redirect_to admin_departments_path, alert: @department.errors.full_messages.to_sentence
    end
  end

  private

  def set_department
    @department = Department.find(params[:id])
  end

  def department_params
    params.require(:department).permit(:name)
  end
end
