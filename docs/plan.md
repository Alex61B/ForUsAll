# Implementation Plan — Employee Time-Off Tracking System

**Date**: 2026-05-17  
**State**: PLAN  

---

## Database Schema

### Table: `departments`
| Column | Type | Constraints |
|--------|------|-------------|
| id | bigint | PK |
| name | string(100) | NOT NULL, UNIQUE |
| created_at | datetime | NOT NULL |
| updated_at | datetime | NOT NULL |

Associations: `has_many :users`

---

### Table: `users`
| Column | Type | Constraints |
|--------|------|-------------|
| id | bigint | PK |
| email | string(255) | NOT NULL, UNIQUE |
| encrypted_password | string | NOT NULL |
| first_name | string(100) | NOT NULL |
| last_name | string(100) | NOT NULL |
| role | integer | NOT NULL, DEFAULT 0 (enum: employee=0, manager=1, admin=2) |
| department_id | bigint | FK → departments, NULL, INDEX |
| manager_id | bigint | FK → users (self-ref), NULL, INDEX |
| reset_password_token | string | NULL, UNIQUE INDEX |
| reset_password_sent_at | datetime | NULL |
| remember_created_at | datetime | NULL |
| created_at | datetime | NOT NULL |
| updated_at | datetime | NOT NULL |

Associations:
- `belongs_to :department, optional: true`
- `belongs_to :manager, class_name: "User", optional: true`
- `has_many :direct_reports, class_name: "User", foreign_key: :manager_id`
- `has_many :time_off_requests`
- `has_many :approvals, foreign_key: :approver_id`

Helper: `#full_name` → `"#{first_name} #{last_name}"`

---

### Table: `time_off_requests`
| Column | Type | Constraints |
|--------|------|-------------|
| id | bigint | PK |
| user_id | bigint | FK → users, NOT NULL, INDEX |
| leave_type | integer | NOT NULL (enum: vacation=0, sick=1, personal=2) |
| start_date | date | NOT NULL |
| end_date | date | NOT NULL |
| reason | text | NULL |
| status | integer | NOT NULL, DEFAULT 0 (enum: pending=0, approved=1, denied=2, cancelled=3) |
| reviewed_by_id | bigint | FK → users, NULL, INDEX |
| reviewed_at | datetime | NULL |
| created_at | datetime | NOT NULL |
| updated_at | datetime | NOT NULL |

Indexes: `[user_id, status]`, `[user_id, leave_type, status]`

Associations:
- `belongs_to :user`
- `belongs_to :reviewed_by, class_name: "User", optional: true`
- `has_one :approval`

Constants: `ANNUAL_VACATION_LIMIT = 15`

---

### Table: `approvals`
| Column | Type | Constraints |
|--------|------|-------------|
| id | bigint | PK |
| time_off_request_id | bigint | FK → time_off_requests, NOT NULL, UNIQUE INDEX |
| approver_id | bigint | FK → users, NOT NULL, INDEX |
| decision | integer | NOT NULL (enum: approved=0, denied=1) |
| notes | text | NULL |
| created_at | datetime | NOT NULL |
| updated_at | datetime | NOT NULL |

Associations:
- `belongs_to :time_off_request`
- `belongs_to :approver, class_name: "User"`

---

## Routes

### HTML Routes (serve ERB views)

```
GET    /                                    → dashboard#index
GET    /dashboard                           → dashboard#index

# Devise (HTML)
GET    /users/sign_in                       → devise/sessions#new
POST   /users/sign_in                       → devise/sessions#create
DELETE /users/sign_out                      → devise/sessions#destroy
GET    /users/password/new                  → devise/passwords#new
POST   /users/password                      → devise/passwords#create
GET    /users/password/edit                 → devise/passwords#edit
PATCH  /users/password                      → devise/passwords#update

# Profile
GET    /profile                             → users#show
GET    /profile/edit                        → users#edit
PATCH  /profile                             → users#update

# Time-Off Requests
GET    /time_off_requests                   → time_off_requests#index
GET    /time_off_requests/new               → time_off_requests#new
POST   /time_off_requests                   → time_off_requests#create
GET    /time_off_requests/:id               → time_off_requests#show
PATCH  /time_off_requests/:id/cancel        → time_off_requests#cancel
PATCH  /time_off_requests/:id/approve       → time_off_requests#approve
PATCH  /time_off_requests/:id/deny          → time_off_requests#deny

# Admin namespace
GET    /admin/users                         → admin/users#index
GET    /admin/users/:id                     → admin/users#show
GET    /admin/users/:id/edit                → admin/users#edit
PATCH  /admin/users/:id                     → admin/users#update
GET    /admin/time_off_requests             → admin/time_off_requests#index
GET    /admin/departments                   → admin/departments#index
POST   /admin/departments                   → admin/departments#create
GET    /admin/departments/new               → admin/departments#new
GET    /admin/departments/:id/edit          → admin/departments#edit
PATCH  /admin/departments/:id               → admin/departments#update
DELETE /admin/departments/:id               → admin/departments#destroy
```

### API Routes (JSON:API, namespace `/api/v1`)

```
POST   /api/v1/auth/sign_in                 → api/v1/sessions#create
DELETE /api/v1/auth/sign_out                → api/v1/sessions#destroy

GET    /api/v1/users                        → api/v1/users#index
GET    /api/v1/users/:id                    → api/v1/users#show
PATCH  /api/v1/users/:id                    → api/v1/users#update

GET    /api/v1/departments                  → api/v1/departments#index
GET    /api/v1/departments/:id              → api/v1/departments#show

GET    /api/v1/time_off_requests            → api/v1/time_off_requests#index
POST   /api/v1/time_off_requests            → api/v1/time_off_requests#create
GET    /api/v1/time_off_requests/:id        → api/v1/time_off_requests#show
PATCH  /api/v1/time_off_requests/:id        → api/v1/time_off_requests#update
DELETE /api/v1/time_off_requests/:id        → api/v1/time_off_requests#destroy
PATCH  /api/v1/time_off_requests/:id/approve → api/v1/time_off_requests#approve
PATCH  /api/v1/time_off_requests/:id/deny   → api/v1/time_off_requests#deny
PATCH  /api/v1/time_off_requests/:id/cancel → api/v1/time_off_requests#cancel

GET    /api/v1/approvals                    → api/v1/approvals#index
GET    /api/v1/approvals/:id                → api/v1/approvals#show
```

---

## Business Logic — Validations

### TimeOffRequest validations
1. `start_date >= Date.today` — "Start date cannot be in the past"
2. `end_date >= start_date` — "End date must be on or after start date"
3. Overlap check — scope: same user, status IN (pending, approved), date ranges intersect
4. Annual vacation limit (15 days) — scope: same user, leave_type=vacation, status IN (pending, approved), year of start_date

### Overlap SQL
```sql
WHERE user_id = :uid
  AND status IN (0, 1)   -- pending, approved
  AND start_date <= :end_date
  AND end_date >= :start_date
  AND id != :self_id      -- exclude self on update
```

### Annual Limit Check (Ruby)
```ruby
existing_days = user.time_off_requests
  .where(leave_type: :vacation, status: [:pending, :approved])
  .where("EXTRACT(year FROM start_date) = ?", start_date.year)
  .where.not(id: id)
  .sum("end_date - start_date + 1")
errors.add(:base, "...") if existing_days + duration_days > ANNUAL_VACATION_LIMIT
```

---

## Background Job Strategy

### Jobs

**NotifyManagerJob** (`notify_manager_job.rb`)
- `perform(time_off_request_id)`
- Triggered: after TimeOffRequest created (pending status)
- Logic: load request → find user.manager → call `TimeOffRequestMailer.request_submitted(request).deliver_now` if manager present
- Rescue: `ActiveRecord::RecordNotFound` → log and return

**NotifyRequesterJob** (`notify_requester_job.rb`)
- `perform(time_off_request_id, decision)`
- Triggered: after approve, deny, cancel actions
- Logic: load request → call appropriate mailer method based on decision
- Decisions: `:approved`, `:denied`, `:cancelled`

### Queue Adapters
| Environment | Adapter | Notes |
|-------------|---------|-------|
| development | :async | Threaded in-process |
| test | :test | Jobs enqueued, not executed |
| production | :async | Swap to Sidekiq later |

### Enqueue Points
Jobs are enqueued in controllers after save, NOT in model callbacks.

---

## Acceptance Criteria

| ID | Feature | Criterion |
|----|---------|-----------|
| AC-1 | Auth | Unauthenticated user redirected to /users/sign_in |
| AC-2 | Auth | POST /api/v1/auth/sign_in returns 200 + session on valid creds |
| AC-3 | Auth | POST /api/v1/auth/sign_in returns 401 JSON:API error on invalid creds |
| AC-4 | Roles | Default role on signup is `employee` |
| AC-5 | Roles | Employee accessing /admin returns 403 |
| AC-6 | Profile | Employee can update own first_name, last_name, email |
| AC-7 | Requests | POST /api/v1/time_off_requests creates pending request |
| AC-8 | Business Rule | start_date < today → validation error |
| AC-9 | Business Rule | end_date < start_date → validation error |
| AC-10 | Business Rule | Overlapping pending/approved request → validation error |
| AC-11 | Business Rule | Vacation over 15 days/year → validation error |
| AC-12 | Business Rule | sick/personal not capped by annual limit |
| AC-13 | Approval | Manager approves direct report → status=approved, Approval record created |
| AC-14 | Approval | Manager cannot approve non-direct-report → 403 |
| AC-15 | Approval | Admin approves any request → status=approved |
| AC-16 | Cancellation | Employee cancels own pending request → status=cancelled |
| AC-17 | Cancellation | Employee cannot cancel approved request → 422 |
| AC-18 | Notifications | NotifyManagerJob enqueued after request created |
| AC-19 | Notifications | NotifyRequesterJob enqueued after approve/deny |
| AC-20 | JSON:API | All API responses: Content-Type: application/vnd.api+json |
| AC-21 | JSON:API | Validation errors: JSON:API errors format |
| AC-22 | History | Employee sees only own requests |
| AC-23 | History | Manager sees own + direct reports' requests |
| AC-24 | History | Admin sees all requests |
| AC-25 | Admin | /admin/* only accessible by role=admin |

---

## Environment Setup (IMPLEMENT Step 1)

**Ruby prerequisite**: System Ruby 2.6 is incompatible with Rails 8. IMPLEMENT must:
1. Install rbenv: `brew install rbenv ruby-build`
2. Install Ruby 3.3.x: `rbenv install 3.3.4 && rbenv global 3.3.4`
3. Install Rails: `gem install rails`

**Rails initialization**: `scripts/init_rails.sh` runs `rails new` and registers all generated files in `.workflow_plan_files` before the drift checker can flag them (single atomic bash command).

---

## IMPLEMENT Order

1. Environment setup (rbenv, Ruby 3.3, Rails gem)
2. `bash scripts/init_rails.sh` — rails new + plan manifest update (atomic)
3. Modify Gemfile — add all gems
4. `bundle install`
5. Configure database.yml + create DB
6. Devise setup (install + generate User migration)
7. Create migrations (5 files with fixed timestamps)
8. Run migrations
9. Models (validations, associations, enums, constants)
10. Pundit policies
11. Serializers
12. Controllers (HTML) + routes
13. Controllers (API) + routes
14. Views (layouts, shared partials, feature views)
15. Mailers + jobs
16. Seeds
17. RSpec setup + specs
18. RuboCop config
19. README + docs/api.md
