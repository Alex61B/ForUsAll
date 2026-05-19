# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_17_000005) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "approvals", force: :cascade do |t|
    t.bigint "approver_id", null: false
    t.datetime "created_at", null: false
    t.integer "decision", null: false
    t.text "notes"
    t.bigint "time_off_request_id", null: false
    t.datetime "updated_at", null: false
    t.index ["approver_id"], name: "index_approvals_on_approver_id"
    t.index ["time_off_request_id"], name: "index_approvals_on_time_off_request_id", unique: true
  end

  create_table "departments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", limit: 100, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_departments_on_name", unique: true
  end

  create_table "time_off_requests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "end_date", null: false
    t.integer "leave_type", null: false
    t.text "reason"
    t.datetime "reviewed_at"
    t.bigint "reviewed_by_id"
    t.date "start_date", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["reviewed_by_id"], name: "index_time_off_requests_on_reviewed_by_id"
    t.index ["user_id", "leave_type", "status"], name: "index_time_off_requests_on_user_id_and_leave_type_and_status"
    t.index ["user_id", "status"], name: "index_time_off_requests_on_user_id_and_status"
    t.index ["user_id"], name: "index_time_off_requests_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "department_id"
    t.string "email", limit: 255, default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name", limit: 100, null: false
    t.string "last_name", limit: 100, null: false
    t.bigint "manager_id"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["department_id"], name: "index_users_on_department_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["manager_id"], name: "index_users_on_manager_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "approvals", "time_off_requests"
  add_foreign_key "approvals", "users", column: "approver_id"
  add_foreign_key "time_off_requests", "users"
  add_foreign_key "time_off_requests", "users", column: "reviewed_by_id"
  add_foreign_key "users", "departments"
  add_foreign_key "users", "users", column: "manager_id"
end
