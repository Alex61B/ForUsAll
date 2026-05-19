# Research — Employee Time-Off Tracking System

**Date**: 2026-05-17  
**State**: RESEARCH  

---

## Requirements Summary

### 1. Employee Management
- Register and login via Devise (email/password)
- User profile: name, email, department (belongs_to Department), manager (self-referential belongs_to User)
- Roles: `employee`, `manager`, `admin` — stored as enum on User model
- Employees can view/edit their own profile

### 2. Time-Off Requests
- Submit requests with: type (vacation/sick/personal), start_date, end_date, reason (text)
- Status lifecycle: `pending` → `approved` | `denied`
- Business rules:
  - Start date must be today or future (no past requests)
  - End date must be >= start date
  - Overlapping pending/approved requests are blocked (validation error, not just flag)
  - Annual vacation limit: 15 days default (configurable via constant)
  - Sick leave and personal leave: no annual cap
- Employees can cancel their own pending requests
- View request history (own requests; managers see direct reports; admins see all)

### 3. Approval Workflow
- Managers approve/deny requests for their **direct reports only** (one-level hierarchy)
- Admins can approve/deny any request
- Each approval/denial creates an `Approval` audit record (approver, decision, timestamp, notes)
- Email notifications sent via ActiveJob + ActionMailer when status changes
- Notifications sent to: requester (on decision), manager (on new request from direct report)

### 4. API & Frontend
- JSON:API compliant REST endpoints (content-type: `application/vnd.api+json`)
- JSON:API serializers via `jsonapi-serializer` gem
- HTML views rendered by Rails (no React/Vue)
- Bootstrap 5 via CDN for styling
- API documentation in `docs/api.md`

---

## Stack Choices

| Component | Choice | Rationale |
|-----------|--------|-----------|
| **Ruby** | 3.3.x (via Homebrew) | Rails 8 requires Ruby >= 3.1; system Ruby 2.6 incompatible; `brew install ruby` provides 3.x |
| **Rails** | 8.0 | Required by spec; latest stable with Hotwire defaults (unused but harmless) |
| **Database** | PostgreSQL 16 (already installed) | Required; available via Homebrew |
| **Authentication** | Devise 4.9+ | Required by spec; production-grade email/password auth; provides helpers for role checks |
| **Authorization** | Pundit 2.x | Clean policy objects; maps well to Employee/Manager/Admin role model; explicit, testable |
| **Serializers** | jsonapi-serializer 2.x | Lightweight JSON:API compliance; successor to fast_jsonapi; no DSL overhead |
| **Testing** | RSpec 3.x + FactoryBot + Shoulda-Matchers | Required; FactoryBot for fixtures; Shoulda for model validation tests |
| **Background Jobs** | ActiveJob with Async adapter | Notification delivery; Async adapter sufficient for dev/test; no Sidekiq dependency needed |
| **Mailer** | ActionMailer (built-in) | Email notifications; deliveries intercepted in test env |
| **Linting** | RuboCop + rubocop-rails | Code quality; `.rubocop.yml` will be configured |
| **Frontend** | Rails ERB views + Bootstrap 5 CDN | Required (no JS framework); Bootstrap via importmap or CDN tag |
| **Pagination** | kaminari | Standard Rails pagination for request history lists |

---

## Environment Verification

| Check | Status | Notes |
|-------|--------|-------|
| System Ruby | 2.6.10 — **INCOMPATIBLE** | System Ruby too old for Rails 8 |
| Homebrew Ruby | Not yet installed | `brew install ruby` installs 3.x keg-only at `/opt/homebrew/opt/ruby` |
| PostgreSQL | 16.13 installed | Available at `/opt/homebrew/bin/psql` |
| Homebrew | 5.1.10 | Available; will be used to install Ruby 3.x |
| Git | Available | At `/opt/homebrew/bin/git` |

**Ruby installation plan**: `brew install ruby` then set PATH in `.ruby-version` or shell profile. Alternatively, install `rbenv` + `ruby-build` for version pinning. Recommending rbenv for reproducibility.

---

## Risks & Edge Cases

### Risk 1: System Ruby Incompatibility (CRITICAL)
- **Issue**: System Ruby 2.6.10 is incompatible with Rails 8 (requires >= 3.1). No rbenv/rvm installed.
- **Mitigation**: Install rbenv + ruby-build via Homebrew, then install Ruby 3.3.x. Add `.ruby-version` file to pin version. Document in README setup instructions.

### Risk 2: Overlapping Request Detection
- **Issue**: Determining overlap between date ranges requires careful SQL. Naive Ruby loop won't scale. Edge cases: same-day requests, partial overlaps, denied requests (should be excluded from overlap check).
- **Mitigation**: Use SQL overlap condition: `start_date <= :end_date AND end_date >= :start_date` scoped to `status IN ('pending', 'approved')`. Wrap in an ActiveRecord scope. Cover with model unit tests.

### Risk 3: Annual Vacation Limit Enforcement
- **Issue**: Counting approved vacation days for current calendar year must exclude denied/cancelled requests and handle requests that span year boundaries correctly.
- **Mitigation**: Scope query to `EXTRACT(year FROM start_date) = CURRENT_YEAR AND status IN ('pending', 'approved') AND time_off_type = 'vacation'`. Sum `(end_date - start_date + 1)` in Ruby. Add validation in TimeOffRequest before save. Make limit configurable via `ANNUAL_VACATION_LIMIT_DAYS = 15` constant.

### Risk 4: Manager Hierarchy Authorization
- **Issue**: A manager approving requests for non-direct-reports is a security boundary. Self-referential User association must be queried correctly.
- **Mitigation**: Pundit policy `TimeOffRequestPolicy#approve?` checks `current_user.managed_users.include?(record.user)`. `managed_users` = `User.where(manager_id: current_user.id)`. Enforce at policy layer, not just controller. Cover with request specs.

### Risk 5: JSON:API Compliance
- **Issue**: JSON:API requires specific envelope format, content-type headers, error format, and relationship links. Partial compliance breaks clients.
- **Mitigation**: Use `jsonapi-serializer` gem consistently. Set `Content-Type: application/vnd.api+json` in a `before_action`. Return JSON:API error objects on validation failure. Document all endpoints in `docs/api.md`.

### Risk 6: Rails 8 `rails new` Defaults
- **Issue**: Rails 8 generates apps with Propshaft, Hotwire (Turbo/Stimulus), and importmap by default. These aren't needed and may add complexity.
- **Mitigation**: Use `rails new --skip-hotwire --skip-jbuilder --asset-pipeline=sprockets` (or configure manually). Bootstrap via CDN link tag avoids asset pipeline complexity entirely.

---

## Assumptions & Open Questions

### Resolved Assumptions
- **Overlap policy**: Block overlapping requests with a validation error (not just a warning). Only `pending` and `approved` statuses count for overlap detection; `denied` and `cancelled` do not block new requests.
- **Annual limit scope**: Applies only to `vacation` type. `sick` and `personal` are uncapped. Counts requests in `pending` or `approved` status within current calendar year.
- **Manager hierarchy depth**: One level only. A manager can only approve their direct reports (`manager_id = current_user.id` on the requester's User record).
- **Cancellation**: Employees can cancel their own `pending` requests only. Approved requests cannot be self-cancelled (requires admin).
- **Audit record**: `Approval` model stores: `time_off_request_id`, `approver_id`, `decision` (approved/denied), `notes`, `created_at`. One record per decision event.
- **Default vacation limit**: 15 days/year, stored as application constant `TimeOffRequest::ANNUAL_VACATION_LIMIT`.

### Open Questions (Non-blocking — decided here)
- Q: Should requests spanning year boundaries count against current or next year's limit?  
  A: Count all days against the year in which `start_date` falls.
- Q: Can a manager also be an employee (submit their own requests)?  
  A: Yes. Role = `manager` but they can still submit requests; their requests are approved by their own manager or an admin.
- Q: Do admins need approval from anyone?  
  A: No. Admin requests are auto-approved or require another admin.

---

## Out of Scope

- Multi-level manager approval chains (only direct manager approves)
- OAuth / SSO / SAML authentication
- Calendar integration (Google Calendar, iCal export)
- Real-time notifications (no ActionCable/WebSockets)
- Carry-over of unused vacation days between calendar years
- Approval rules varying by request duration (mentioned in Task.md as an example, not a hard requirement)
- Mobile-specific UI
- File attachments (e.g., doctor's notes for sick leave)
- Public API versioning (v1 prefix is fine but no versioning strategy needed)

---

## Readiness Verdict: READY FOR PLANNING

All functional requirements from Task.md have been analyzed. Six technical risks are identified with concrete mitigations. Stack choices are justified. All open questions are resolved. Environment gap (Ruby version) is documented with a mitigation plan. No unresolved blockers.
