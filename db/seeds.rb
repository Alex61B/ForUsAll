puts "Seeding database..."

# Departments
engineering = Department.find_or_create_by!(name: "Engineering")
product     = Department.find_or_create_by!(name: "Product")
design      = Department.find_or_create_by!(name: "Design")
hr          = Department.find_or_create_by!(name: "Human Resources")

puts "  Created #{Department.count} departments"

# Admin
admin = User.find_or_create_by!(email: "admin@example.com") do |u|
  u.first_name = "Admin"
  u.last_name  = "User"
  u.password   = "password123"
  u.role       = :admin
  u.department = hr
end

# Manager
manager = User.find_or_create_by!(email: "manager@example.com") do |u|
  u.first_name = "Jane"
  u.last_name  = "Manager"
  u.password   = "password123"
  u.role       = :manager
  u.department = engineering
end

# Employees
emp1 = User.find_or_create_by!(email: "alice@example.com") do |u|
  u.first_name = "Alice"
  u.last_name  = "Smith"
  u.password   = "password123"
  u.role       = :employee
  u.department = engineering
  u.manager    = manager
end

emp2 = User.find_or_create_by!(email: "bob@example.com") do |u|
  u.first_name = "Bob"
  u.last_name  = "Jones"
  u.password   = "password123"
  u.role       = :employee
  u.department = engineering
  u.manager    = manager
end

emp3 = User.find_or_create_by!(email: "carol@example.com") do |u|
  u.first_name = "Carol"
  u.last_name  = "Davis"
  u.password   = "password123"
  u.role       = :employee
  u.department = product
end

puts "  Created #{User.count} users"

# Time off requests
unless TimeOffRequest.exists?
  # Approved request
  approved_req = emp1.time_off_requests.create!(
    leave_type: :vacation,
    start_date: Date.today + 14,
    end_date:   Date.today + 18,
    reason:     "Summer vacation",
    status:     :approved,
    reviewed_by: manager,
    reviewed_at: Time.current
  )
  Approval.create!(
    time_off_request: approved_req,
    approver:         manager,
    decision:         :approved,
    notes:            "Approved — enjoy your vacation!"
  )

  # Pending request
  emp2.time_off_requests.create!(
    leave_type: :sick,
    start_date: Date.today + 3,
    end_date:   Date.today + 4,
    reason:     "Medical appointment"
  )

  # Denied request
  denied_req = emp3.time_off_requests.create!(
    leave_type: :personal,
    start_date: Date.today + 7,
    end_date:   Date.today + 7,
    status:     :denied,
    reviewed_by: admin,
    reviewed_at: Time.current
  )
  Approval.create!(
    time_off_request: denied_req,
    approver:         admin,
    decision:         :denied,
    notes:            "Staffing constraints this week."
  )
end

puts "  Created #{TimeOffRequest.count} time off requests"
puts "Seeding complete!"
puts ""
puts "Login credentials:"
puts "  Admin:   admin@example.com / password123"
puts "  Manager: manager@example.com / password123"
puts "  Employee: alice@example.com / password123"
