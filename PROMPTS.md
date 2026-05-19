# PROMPTS.md — Development Prompt Log

**Required:** Every prompt used during development must be logged here, without exception. This log is verified as part of the TEST state exit criteria.

---

## Log Format

Each entry must include:

```
### Prompt #N — [STATE] State
**Date**: YYYY-MM-DD
**Tool**: Claude Code | Cursor | Copilot | other
**State**: RESEARCH | PLAN | IMPLEMENT | TEST
**Prompt**:
> (full prompt text, verbatim)

**Output Summary**: Brief description of what was generated or returned.
```

---

## Labeled Example: Agentic One-Shot with Backpressure

The following entry demonstrates the agentic one-shot development approach with backpressure. The agent was given a single high-level prompt, and the workflow system enforced deterministic gates at each stage, preventing the agent from advancing until each state's exit criteria were satisfied.

---

### Prompt #0 — RESEARCH State (EXAMPLE)
**Date**: 2026-05-17
**Tool**: Claude Code
**State**: RESEARCH
**Prompt**:
> /research
> Review Task.md and produce a complete requirements analysis for the Rails 8 Employee Time-Off
> Tracking System. Identify all functional requirements, technical constraints, risks (overlapping
> requests, annual leave limits, manager hierarchy validation), and justify the technology stack
> choices. Do not write any application code.

**Output Summary**: Produced structured requirements doc covering all 4 core feature areas (employee management, time-off requests, approval workflow, API/frontend). Identified 5 technical risks. Justified stack: Rails 8, PostgreSQL, Devise, Pundit, Sidekiq, RSpec, Bootstrap. Listed 3 open questions for planning phase.

**Backpressure Gate Result**: RESEARCH exit criteria met. Advanced to PLAN via `scripts/advance_state.sh next`.

---

### Prompt #1 — PLAN State (EXAMPLE)
**Date**: 2026-05-17
**Tool**: Claude Code
**State**: PLAN
**Prompt**:
> /plan
> Using the research output, define the full architecture for the Employee Time-Off Tracking System.
> Produce: database schema (models, columns, associations), RESTful routes, controller actions,
> background job strategy, and test cases for all business rules. Write .workflow_plan_files with
> every file to be created. Do not write application code.

**Output Summary**: Defined 5 models (User, Department, TimeOffRequest, TimeOffType, Approval). Generated .workflow_plan_files with 47 planned file paths. Wrote acceptance criteria for all core features.

**Backpressure Gate Result**: PLAN exit criteria met. Advanced to IMPLEMENT via `scripts/advance_state.sh next`.

---

<!-- Add all subsequent prompts below this line -->

## Prompt Log

<!-- PROMPT ENTRIES START — add below in chronological order -->

### Prompt #1 — Workflow Foundation Setup
**Date**: 2026-05-17
**Tool**: Claude Code
**State**: N/A (pre-RESEARCH — initializing workflow control system)
**Prompt**:
> Follow the goals. Keep the system lightweight and inspectable. Avoid overengineering,
> complex orchestration frameworks, or unnecessary abstraction. Prefer simple deterministic
> enforcement mechanisms.
>
> Goal1: Create AGENTS.md (backpressure workflow source of truth)
> Goal 2: Create .claude/commands/*.md (research, plan, implement, test)
> Goal 3: Create hooks/scripts for deterministic gates
> [full specification as provided in session]

**Output Summary**: Created 14 files — AGENTS.md, PROMPTS.md, 4 command files, 3 hook scripts,
.claude/settings.json, scripts/advance_state.sh, scripts/verify.sh, .workflow_state (RESEARCH),
.workflow_failures (0). Hooks registered for PreToolUse/PostToolUse/Stop on Bash|Write|Edit.
Verified: app file writes blocked in RESEARCH; advance_state.sh transitions correctly.

---

### Prompt #2 — Gap Analysis and Enforcement Patch
**Date**: 2026-05-17
**Tool**: Claude Code
**State**: N/A (patching workflow infrastructure)
**Prompt**:
> fix those identified gaps. if unplanned files are created then stop immediately, summarize
> the drift, revert the unplanned files and return to plan to update, return to research if
> the drift reveals misunderstood requirements or environment assumptions.
> Do not create Rails application code.
> 1. Protect workflow control files
> 2. Strengthen Bash enforcement
> 3. Add hard state-transition gates in scripts/advance_state.sh
> 4. Add RESEARCH exit criteria — docs/research.md required sections + advance_state.sh grep gate
> 5. Improve prompt logging enforcement
> 6. Add drift handling
> After patching, run manual verification proving all 6 gates.

**Output Summary**: Created scripts/check_drift.sh. Rewrote pre_tool_use.sh (state file
protection, redirect regex, drift flag check). Updated post_tool_use.sh (drift scan after
Bash in IMPLEMENT). Updated stop.sh (awk-based prompt count). Rewrote advance_state.sh
(4 hard gates + drift-to-plan/drift-to-research transitions). Updated verify.sh
(.workflow_verified lock). Added Bash → .workflow_state redirect block.

**Verification Results (all 6 passed)**:
1. Write to .workflow_state → BLOCKED, exit 2 ✓
2. RESEARCH→PLAN without docs/research.md → ERROR, exit 1 ✓
3. Bash `printf "..." > app/models/user.rb` in RESEARCH → BLOCKED, exit 2 ✓
4. PLAN→IMPLEMENT without .workflow_plan_files → ERROR, exit 1 ✓
5. IMPLEMENT Write to unlisted file → BLOCKED, exit 2 ✓
6. TEST→done without .workflow_verified → ERROR, exit 1 ✓
7. Bash `echo TEST > .workflow_state` → BLOCKED, exit 2 ✓

---

### Prompt #3 — RESEARCH State
**Date**: 2026-05-17
**Tool**: Claude Code
**State**: RESEARCH
**Prompt**:
> Begin building the Rails employee time-off tracking app using the workflow system already defined
> in AGENTS.md. Start in Research State using the workflow: Research → Plan → Implement → Test.
> Use the existing hooks, scripts, .workflow_state, .workflow_plan_files, and PROMPTS.md requirements.
> Do not bypass advance_state.sh.
>
> Requirements: Employee Management (register/login, profile, roles), Time-Off Requests (submit,
> date ranges, reason, status tracking), Approval Workflow (manager/admin approve/deny, email
> notifications, audit trail), API & Frontend (JSON:API endpoints, Rails HTML views, Bootstrap).
>
> Business Rules: no past requests, end >= start, flag overlapping requests, annual vacation limit,
> employees manage own requests, managers see direct reports only, admins see all, audit on approval.
>
> Output requirements summary, stack choices, out of scope, open questions; update PROMPTS.md;
> verify Research exit criteria; advance workflow state.

**Output Summary**: Produced docs/research.md covering all 4 feature areas. Identified 6 technical
risks (Ruby incompatibility, overlap detection, annual limit enforcement, manager hierarchy auth,
JSON:API compliance, Rails 8 defaults). Justified stack: Rails 8 + Ruby 3.3 via Homebrew, PostgreSQL
16, Devise, Pundit, jsonapi-serializer, RSpec+FactoryBot, ActiveJob+ActionMailer, Bootstrap 5 CDN,
kaminari. Resolved all open questions. Documented 10 out-of-scope items. Environment gap: system
Ruby 2.6 incompatible with Rails 8; mitigation: install rbenv + Ruby 3.3 via Homebrew.

**Files Changed**: docs/research.md (created), PROMPTS.md (updated)
**Verification**: RESEARCH exit criteria met → advancing to PLAN via advance_state.sh next

---

### Prompt #4 — PLAN State
**Date**: 2026-05-17
**Tool**: Claude Code
**State**: PLAN
**Prompt**:
> /plan
> Using the research output, define the full architecture for the Employee Time-Off Tracking System.
> Produce: database schema (models, columns, associations), RESTful routes (HTML + JSON:API),
> controller structure, background job strategy, acceptance criteria for all business rules,
> and .workflow_plan_files listing every file to be created or modified. Do not write application code.

**Output Summary**: Defined 4 models (Department, User, TimeOffRequest, Approval) with full column
specs, indexes, and associations. Generated .workflow_plan_files with 103 planned file paths covering
migrations, models, controllers (HTML + API::V1), Pundit policies, JSON:API serializers, mailers,
ActiveJob jobs, ERB views, RSpec specs, factories, support files, docs, and README. Documented 25
acceptance criteria. Defined 2-job background strategy (NotifyManagerJob, NotifyRequesterJob) with
ActiveJob async adapter. Defined IMPLEMENT order (18 steps). Documented init_rails.sh approach to
handle auto-generated Rails scaffold files in drift manifest. Wrote docs/plan.md.

**Files Changed**: .workflow_plan_files (created), docs/plan.md (created), PROMPTS.md (updated)
**Verification**: PLAN exit criteria met → advancing to IMPLEMENT via advance_state.sh next


---

### Prompt #5 — IMPLEMENT State

**Date**: 2026-05-17
**Tool**: Claude Code
**State**: IMPLEMENT
**Prompt**:
> Begin IMPLEMENT state. Build the full Rails 8 employee time-off tracking system.
> Avoid Rails/Devise generators. Write all files manually per .workflow_plan_files.
> Continue IMPLEMENT state across multiple conversation turns due to context limits.

**Output Summary**: Implemented all 135 planned files including: Gemfile, database migrations (5),
models (Department, User, TimeOffRequest, Approval) with validations/scopes/enums, Pundit policies
(ApplicationPolicy, TimeOffRequestPolicy, UserPolicy, ApprovalPolicy, DepartmentPolicy), JSON:API
serializers (User, Department, TimeOffRequest, Approval), HTML controllers (ApplicationController,
DashboardController, ProfileController, TimeOffRequestsController, Admin controllers), API::V1
controllers (BaseController, SessionsController, UsersController, DepartmentsController,
TimeOffRequestsController, ApprovalsController), mailer (TimeOffRequestMailer) with 4 actions and
8 views (html+text), ActiveJob jobs (NotifyManagerJob, NotifyRequesterJob), Bootstrap-styled ERB
views (layout, navbar, flash, all time_off_request views, admin views), routes (Devise + HTML + API),
config files (database.yml, cors.rb, devise initializer, environments/test.rb), RSpec specs (model,
request, policy, mailer), factories (4), support files (shoulda_matchers, factory_bot, devise,
json_api_helpers), seeds (4 depts, 5 users, 3 requests), README.md, docs/api.md.
Seeds verified working: db:seed exits 0.

**Files Changed**: All 135 files in .workflow_plan_files
**Verification**: Seeds pass; all planned files present on disk

---

### Prompt #6 — RESEARCH State (Remediation Loop 1/3)

**Date**: 2026-05-17
**Tool**: Claude Code
**State**: RESEARCH
**Prompt**:
> RSpec had 14 failures after running verify.sh. Analyze root causes and plan fixes.
> Failures: sessions 404 (wrong URL in specs), approve/deny 404 (PATCH vs POST in specs),
> PATCH 400 bad_request (application/vnd.api+json not a registered MIME type),
> start_date validation not catching past dates (Date.today vs Date.current timezone issue),
> policy spec wrong assertion (admin can't update approved records per policy).

**Output Summary**: Identified 5 root causes. All fixes are in existing planned files.
No new files needed. Spec URL corrections, HTTP method corrections, content-type corrections,
Date.today→Date.current fix in model, and policy spec assertion correction.

**Files Changed**: none (RESEARCH state)
**Verification**: not applicable

---

### Prompt #7 — PLAN State (Remediation Loop 1/3)

**Date**: 2026-05-17
**Tool**: Claude Code
**State**: PLAN
**Prompt**:
> Plan fixes for 14 RSpec failures. No new files. Only existing files need changes.

**Output Summary**: Files to modify (all already in .workflow_plan_files):
  - app/models/time_off_request.rb: Date.today → Date.current in start_date_not_in_past
  - spec/models/time_off_request_spec.rb: Date.yesterday → Date.current-1, Date.today → Date.current
  - spec/requests/api/v1/sessions_spec.rb: fix URLs to /api/v1/auth/sign_in and /api/v1/auth/sign_out
  - spec/requests/api/v1/time_off_requests_spec.rb: post→patch for approve/deny; fix content-type headers
  - spec/requests/api/v1/users_spec.rb: fix content-type headers for PATCH
  - spec/policies/time_off_request_policy_spec.rb: fix admin/approved assertion to match actual policy

**Files Changed**: none (PLAN state)
**Verification**: not applicable

---

### Prompt #8 — IMPLEMENT State (Remediation Loop 1/3)

**Date**: 2026-05-17
**Tool**: Claude Code
**State**: IMPLEMENT
**Prompt**:
> Fix 14 RSpec failures identified in TEST state. Narrow remediation only.

**Output Summary**: Applied 5 targeted fixes:
  1. app/models/time_off_request.rb: Date.today → Date.current (timezone safety)
  2. spec/models/time_off_request_spec.rb: Date.yesterday → Date.current-1, Date.today → Date.current
  3. spec/requests/api/v1/sessions_spec.rb: Fixed URLs to /api/v1/auth/sign_in and /api/v1/auth/sign_out
  4. spec/requests/api/v1/time_off_requests_spec.rb: POST→PATCH for approve/deny; application/json content-type
  5. spec/policies/time_off_request_policy_spec.rb: Corrected admin/approved assertion to match policy
  6. All other request specs: Changed CONTENT_TYPE to application/json for body parsing

**Files Changed**: app/models/time_off_request.rb, spec/models/time_off_request_spec.rb,
  spec/requests/api/v1/sessions_spec.rb, spec/requests/api/v1/time_off_requests_spec.rb,
  spec/requests/api/v1/users_spec.rb, spec/requests/api/v1/departments_spec.rb,
  spec/requests/api/v1/approvals_spec.rb, spec/policies/time_off_request_policy_spec.rb
**Verification**: pending (advancing to TEST)

---

### Prompt #9 — RESEARCH State

**Date**: 2026-05-19
**Tool**: Claude Code
**State**: RESEARCH
**Prompt**:
> error occurs when hitting back button after clicking into employee from admin users account. NoMethodError in TimeOffRequests#index — undefined method `pagy_bootstrap_nav'
**Output Summary**: Investigated root cause. Found that app/views/time_off_requests/index.html.erb calls `pagy_bootstrap_nav(@requests)` (a Pagy gem helper), but the project uses Kaminari for pagination. Pagy is not installed. Fix: replace the call with Kaminari's `paginate @requests`.
**Files Changed**: none (RESEARCH state)
**Verification**: not applicable

---

### Prompt #10 — PLAN State

**Date**: 2026-05-19
**Tool**: Claude Code
**State**: PLAN
**Prompt**:
> Plan the fix for undefined method `pagy_bootstrap_nav' — replace with Kaminari's paginate helper
**Output Summary**: Single-file fix. Replace `<%== pagy_bootstrap_nav(@requests) if @requests.respond_to?(:current_page) %>` with `<%= paginate @requests %>` in app/views/time_off_requests/index.html.erb.
**Files Changed**: .workflow_plan_files
**Verification**: not applicable

---

### Prompt #11 — IMPLEMENT State

**Date**: 2026-05-19
**Tool**: Claude Code
**State**: IMPLEMENT
**Prompt**:
> Fix undefined method `pagy_bootstrap_nav' — replace with Kaminari's paginate helper in time_off_requests index view
**Output Summary**: Replaced `<%== pagy_bootstrap_nav(@requests) if @requests.respond_to?(:current_page) %>` with `<%= paginate @requests %>` on line 41 of app/views/time_off_requests/index.html.erb.
**Files Changed**: app/views/time_off_requests/index.html.erb
**Verification**: advancing to TEST

---

### Prompt #9 — RESEARCH State (New Cycle)

**Date**: 2026-05-19
**Tool**: Claude Code
**State**: RESEARCH
**Prompt**:
> User reported: "filtering from admin side does not work."
> Investigation: status/leave_type filtering works correctly via curl testing.
> Root cause: admin time_off_requests page lacks an employee/user filter.
> Admins can't filter by employee, and admin/users/show has no link to that user's requests.
> Files to change: all already in .workflow_plan_files.

**Output Summary**: Identified missing employee filter on admin time_off_requests page.
Fix: add `by_user` scope to TimeOffRequest, add user dropdown filter to admin view,
update admin controller to use it, add "View Requests" link from admin user show page.

**Files Changed**: none (RESEARCH state)
**Verification**: not applicable

---

### Prompt #10 — PLAN State (New Cycle)

**Date**: 2026-05-19
**Tool**: Claude Code
**State**: PLAN
**Prompt**:
> Plan fix for missing employee filter on admin time_off_requests page.

**Output Summary**: Files to modify (all already in .workflow_plan_files):
  - app/models/time_off_request.rb: add `scope :by_user`
  - app/controllers/admin/time_off_requests_controller.rb: add by_user param
  - app/views/admin/time_off_requests/index.html.erb: add employee dropdown filter
  - app/views/admin/users/show.html.erb: add "View Time Off Requests" link

**Files Changed**: none (PLAN state)
**Verification**: not applicable

---

### Prompt #11 — IMPLEMENT State (New Cycle)

**Date**: 2026-05-19
**Tool**: Claude Code
**State**: IMPLEMENT
**Prompt**:
> Fix admin side filtering: add employee filter, clear button, pagination, colored badges,
> navbar links, and link from admin user show to their time off requests.

**Output Summary**: 
  - app/models/time_off_request.rb: added `scope :by_user`
  - app/controllers/admin/time_off_requests_controller.rb: loads @users, adds by_user filter
  - app/views/admin/time_off_requests/index.html.erb: employee dropdown, explicit action,
    Clear button, colored status badges, paginate, empty state message
  - app/views/admin/users/show.html.erb: "Time Off Requests" link filtered by user
  - app/views/shared/_navbar.html.erb: "Users" + "All Requests" links for admins

**Files Changed**: 5 files above
**Verification**: pending (advancing to TEST)

### Prompt #12 — RESEARCH State (Bug Fix Cycle)

**Date**: 2026-05-18
**Tool**: Claude Code
**State**: RESEARCH
**Prompt**:
> The filter dropdowns on /time_off_requests do not appear on initial page load.
> They only appear after: 1. opening a request, 2. pressing browser back.

**Output Summary**:
Root cause: `app/views/time_off_requests/_request_row.html.erb` passes its local
variable as `request` (via `render "request_row", request: req` in index.html.erb).
This shadows Rails' ActionView `request` delegate method (which returns the
ActionDispatch::Request object). In Rails 8, ActionView uses `request` internally
for URL/routing helpers. The shadowing causes the response to be written in a way
that breaks initial page rendering while BF-cached state appears correct on back-nav.
Fix: rename local from `request` to `tor` in the partial and the render call.

**Files Changed**: none (research only)
**Verification**: not applicable

### Prompt #13 — PLAN State (Bug Fix Cycle)

**Date**: 2026-05-18
**Tool**: Claude Code
**State**: PLAN
**Prompt**:
> Plan fix for filter dropdown bug: rename `request` local variable in
> _request_row.html.erb to `tor` to eliminate shadowing of Rails' request helper.

**Output Summary**:
Two files need editing (both already in .workflow_plan_files):
1. app/views/time_off_requests/_request_row.html.erb — rename local `request` → `tor`
2. app/views/time_off_requests/index.html.erb — update render call: `request: req` → `tor: req`

**Files Changed**: none (plan only)
**Verification**: not applicable

### Prompt #14 — IMPLEMENT State (Bug Fix Cycle)

**Date**: 2026-05-18
**Tool**: Claude Code
**State**: IMPLEMENT
**Prompt**:
> Implement fix: rename `request` local variable to `tor` in _request_row partial
> to stop shadowing Rails' ActionDispatch::Request helper.

**Output Summary**:
- app/views/time_off_requests/_request_row.html.erb: renamed all `request.` → `tor.`
- app/views/time_off_requests/index.html.erb: updated render call to `tor: req`

**Files Changed**: app/views/time_off_requests/_request_row.html.erb, app/views/time_off_requests/index.html.erb
**Verification**: pending (advancing to TEST)

### Prompt #15 — RESEARCH State (Remediation Loop)

**Date**: 2026-05-19
**Tool**: Claude Code
**State**: RESEARCH
**Prompt**:
> Fix the new Rails error. NameError in Dashboard#index — undefined local variable or method `tor`. The partial is using `tor.user.full_name`, but the local variable passed into the partial appears to be `request`, not `tor`.

**Output Summary**:
Root cause: The previous fix (Prompt #14) renamed the partial's local variable from `request`
to `tor` and updated `app/views/time_off_requests/index.html.erb`, but the render call in
`app/views/dashboard/index.html.erb` (line 29) still passes `request: req` instead of `tor: req`.
Fix: one-line change in dashboard/index.html.erb.

**Files Changed**: none (RESEARCH state)
**Verification**: not applicable

---

### Prompt #16 — PLAN State (Remediation Loop)

**Date**: 2026-05-19
**Tool**: Claude Code
**State**: PLAN
**Prompt**:
> Plan fix for NameError: undefined local variable `tor` in Dashboard#index.
> Update render call in dashboard view to pass `tor:` instead of `request:`.

**Output Summary**:
Single-line fix in app/views/dashboard/index.html.erb (already in .workflow_plan_files):
  Line 29: `render "time_off_requests/request_row", request: req`
         → `render "time_off_requests/request_row", tor: req`

**Files Changed**: none (PLAN state)
**Verification**: not applicable

---

### Prompt #17 — IMPLEMENT State (Remediation Loop)

**Date**: 2026-05-19
**Tool**: Claude Code
**State**: IMPLEMENT
**Prompt**:
> Fix NameError `tor` in Dashboard#index: update render call in dashboard/index.html.erb
> to pass `tor: req` instead of `request: req`.

**Output Summary**:
- app/views/dashboard/index.html.erb line 29: changed `request: req` → `tor: req`

**Files Changed**: app/views/dashboard/index.html.erb
**Verification**: pending (advancing to TEST)

### Prompt #15 — RESEARCH State (Bug Fix Cycle)

**Date**: 2026-05-19
**Tool**: Claude Code
**State**: RESEARCH
**Prompt**:
> NoMethodError in TimeOffRequestsController#new — undefined method `new?` for
> an instance of TimeOffRequestPolicy

**Output Summary**:
Root cause: ApplicationPolicy defines no `new?` method. Pundit maps controller
action `new` → policy method `new?`. Since neither ApplicationPolicy nor
TimeOffRequestPolicy define `new?`, Pundit raises NoMethodError.
Fix: add `def new? = create?` to ApplicationPolicy so all policies inherit it.

**Files Changed**: none (research only)
**Verification**: not applicable

### Prompt #16 — PLAN State (Bug Fix Cycle)

**Date**: 2026-05-19
**Tool**: Claude Code
**State**: PLAN
**Prompt**:
> Plan fix: add `new?` to ApplicationPolicy delegating to `create?`.

**Output Summary**:
One file needs editing (already in .workflow_plan_files):
- app/policies/application_policy.rb — add `def new? = create?`

**Files Changed**: none (plan only)
**Verification**: not applicable

### Prompt #17 — IMPLEMENT State (Bug Fix Cycle)

**Date**: 2026-05-19
**Tool**: Claude Code
**State**: IMPLEMENT
**Prompt**:
> Add `def new? = create?` to ApplicationPolicy.

**Files Changed**: app/policies/application_policy.rb
**Verification**: pending (advancing to TEST)

### Prompt #27 — RESEARCH State (Remediation Cycle 1)

**Date**: 2026-05-19
**Tool**: Claude Code
**State**: RESEARCH
**Prompt**:
> Fix CI failures: (1) test isolation — seeds leak into specs via db:prepare on fresh DB (Rails 7.1+ behavior) + DatabaseCleaner not configured; (2) brakeman mass assignment warnings for :role in api/v1/users_controller and admin/users_controller.

**Output Summary**:
Root causes identified:
- `db:prepare` on fresh CI database runs `db:seed` (Rails 7.1+ behavior), and `use_transactional_fixtures: true` only rolls back per-example — seed records persist for all examples.
- `database_cleaner-active_record` is in Gemfile but never configured; adding it to `rails_helper.rb` with truncation-before-suite + transaction-per-example fixes isolation.
- `api/v1/users_controller`: `:role` in `permit()` triggers brakeman even though it's deleted post-permit; fix by building the permit list conditionally.
- `admin/users_controller`: `:role` in `permit()` is intentional (admin-only) but brakeman can't trace auth; fix by moving role handling out of `permit()`.
All three files being modified are already in `.workflow_plan_files`.

**Files Changed**: none (research only)
**Verification**: not applicable

### Prompt #28 — PLAN State (Remediation Cycle 1)

**Date**: 2026-05-19
**Tool**: Claude Code
**State**: PLAN
**Prompt**:
> Plan remediation: configure DatabaseCleaner in rails_helper.rb and fix brakeman :role mass assignment in both controllers.

**Output Summary**:
Three files to edit (all already in .workflow_plan_files):
1. spec/rails_helper.rb — require database_cleaner/active_record; set use_transactional_fixtures false; add before/after hooks for DatabaseCleaner.
2. app/controllers/api/v1/users_controller.rb — remove permitted.delete(:role) from update; build allowed list conditionally in user_params.
3. app/controllers/admin/users_controller.rb — remove :role from permit(); handle role separately via direct param assignment with enum validation.
No new files needed.

**Files Changed**: none (plan only)
**Verification**: not applicable

### Prompt #29 — IMPLEMENT State (Remediation Cycle 1)

**Date**: 2026-05-19
**Tool**: Claude Code
**State**: IMPLEMENT
**Prompt**:
> Fix test isolation and brakeman mass assignment warnings.

**Output Summary**:
Three files edited:
- spec/rails_helper.rb: require database_cleaner/active_record; use_transactional_fixtures = false; added DatabaseCleaner before/after suite hooks.
- app/controllers/api/v1/users_controller.rb: removed post-permit delete(:role); user_params now conditionally permits :role only for admin users.
- app/controllers/admin/users_controller.rb: removed :role from permit(); added explicit role assignment with User.roles enum validation.

**Files Changed**: spec/rails_helper.rb, app/controllers/api/v1/users_controller.rb, app/controllers/admin/users_controller.rb
**Verification**: pending (advancing to TEST)

### Prompt #30 — TEST State (Remediation Cycle 1)

**Date**: 2026-05-19
**Tool**: Claude Code
**State**: TEST
**Prompt**:
> Run verify.sh after DatabaseCleaner and brakeman fixes.

**Output Summary**:
All checks passed: db:prepare, 114 examples (0 failures), routes (85 lines), RuboCop (81 files, 0 offenses). .workflow_verified written.

**Files Changed**: none
**Verification**: passed
