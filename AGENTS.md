# AGENTS.md — Backpressure Agentic Workflow

This file is the **source of truth** for the agentic workflow that builds the Rails 8 Employee Time-Off Tracking System. All agents, hooks, and scripts defer to rules defined here.

---

## Project Context

This project uses a **deterministic backpressure agentic workflow** to build a Rails 8 employee time-off tracking system with a JSON:API backend, Rails views frontend, PostgreSQL, Devise authentication, role-based access, and RSpec test coverage. The workflow enforces quality gates at each stage before the agent may advance.

---

## Official Workflow

The four required states, in order:

```
RESEARCH → PLAN → IMPLEMENT → TEST
```

An agent **cannot advance** to the next state until the current state satisfies its deterministic exit criteria (backpressure).

**Backpressure definition:** Each state has explicit exit criteria that must be verifiably met before the agent transitions forward. If a gate fails, the agent narrows its behavior to the failing requirement, test, or verification issue only, and remains in a constrained remediation loop until the gate passes.

---

## State Machine

| From | To | Trigger |
|------|----|---------|
| RESEARCH | PLAN | Exit criteria met → `scripts/advance_state.sh next` |
| PLAN | IMPLEMENT | Exit criteria met → `scripts/advance_state.sh next` |
| IMPLEMENT | TEST | Exit criteria met → `scripts/advance_state.sh next` |
| TEST | RESEARCH | Verification failure → `scripts/advance_state.sh fail` |
| TEST | (done) | All checks pass → `scripts/advance_state.sh next` |

State is persisted in `.workflow_state`. Failure count is persisted in `.workflow_failures`.

---

## State Gates

### State 1: RESEARCH

**Purpose:** Understand the requirements, assess technical risks, and justify stack choices before any design decisions are made.

**Allowed actions:**
- Read `Task.md` and any existing project files
- Search documentation, web resources, and examples
- Identify functional requirements, constraints, and edge cases
- List technical risks and open questions
- Choose and justify the technology stack

**Forbidden actions:**
- Writing any application code (`app/`, `db/`, `lib/`, `config/`, `spec/`, `Gemfile`)
- Running `rails generate`, `bundle install`, `rake db:`, or `rspec`
- Creating migrations, models, controllers, or specs

**Exit criteria** (all must be true before advancing):
- [ ] All functional requirements from `Task.md` are listed and understood
- [ ] Technical risks are identified (overlapping requests, annual limits, hierarchy validation)
- [ ] Stack choices are justified (auth, DB, background jobs, testing)
- [ ] Open questions are noted or resolved
- Log the research prompt in `PROMPTS.md` before advancing

---

### State 2: PLAN

**Purpose:** Produce a concrete implementation checklist and acceptance criteria. No application code is written.

**Allowed actions:**
- Define architecture: models, associations, validations, business rules
- Define routes and controller structure
- Define test cases and acceptance criteria
- Write `.workflow_plan_files` (one planned file path per line — required for IMPLEMENT gate)
- Write or update `AGENTS.md`, `PROMPTS.md`, `docs/`, `.claude/`, `scripts/`, or root `*.md` files

**Forbidden actions:**
- Writing application code to `app/`, `db/migrate/`, `spec/`, `lib/`, `config/routes.rb`, or `Gemfile`
- Running generators, migrations, or test suites

**Exit criteria** (all must be true before advancing):
- [ ] `.workflow_plan_files` exists and lists every file to be created or modified
- [ ] Acceptance criteria are written for each core feature
- [ ] Database schema is defined (models, columns, associations)
- [ ] API routes are defined
- [ ] Background job strategy is defined
- Log the planning prompts in `PROMPTS.md` before advancing

---

### State 3: IMPLEMENT

**Purpose:** Build the application exactly as planned. No scope creep.

**Allowed actions:**
- Create or edit files listed in `.workflow_plan_files`
- Write application code, specs, seeds, and documentation
- Run generators whose output matches planned files
- Install gems listed in the plan

**Forbidden actions:**
- Writing to files **not** listed in `.workflow_plan_files` (unplanned files are blocked by hook)
- Adding features not described in the plan
- Refactoring code unrelated to the current plan

**Exit criteria** (all must be true before advancing):
- [ ] Every file in `.workflow_plan_files` exists and is implemented
- [ ] All planned models have validations and associations
- [ ] All planned specs are written (may not yet pass)
- [ ] Seeds file populates a demo dataset
- [ ] Application starts without errors
- Log all implementation prompts in `PROMPTS.md` before advancing

---

### State 4: TEST

**Purpose:** Run deterministic verification checks and confirm all requirements are met.

**Allowed actions:**
- Run `scripts/verify.sh` (db:prepare, RSpec, routes, RuboCop)
- Read output and report failures with specific line references
- Write narrow corrective code **only** for a failing check (if in remediation loop)

**Forbidden actions:**
- Adding new features while any verification check is failing
- Advancing state while any check fails
- Changing test assertions to force a pass

**Exit criteria** (all must be true before calling `advance_state.sh next`):
- [ ] `bundle exec rspec` exits 0 (all specs pass)
- [ ] `bundle exec rails db:prepare` succeeds
- [ ] `bundle exec rails routes` prints the expected routes
- [ ] RuboCop passes (if `.rubocop.yml` is present)
- [ ] `docs/api.md` or Swagger spec is present and current
- [ ] `PROMPTS.md` contains every prompt used during this workflow cycle

---

## Failure Behavior

If any TEST exit criterion fails:

1. Run `scripts/advance_state.sh fail` — this returns the state to RESEARCH and increments `.workflow_failures`.
2. The agent enters a **constrained remediation loop**: `RESEARCH → PLAN → IMPLEMENT → TEST`, scoped **only** to the failing check. No new feature work is permitted.
3. If the same failure repeats **3 times** (`.workflow_failures` reaches 3), `advance_state.sh` will exit with an error and print:

   ```
   BLOCKER: [failure description]
   Attempted: 3 times
   Stop. Summarize the exact failing check, what was tried, and what is blocking resolution.
   ```

4. At that point, stop all code changes and provide a written blocker summary before retrying.

---

## Prompt Logging Rule

`PROMPTS.md` must contain every prompt used during development — no exceptions. See `PROMPTS.md` for format and a labeled example. Logging is verified as part of the TEST state exit criteria. The `stop.sh` hook will remind the agent to log after each session.

---

## Hook and Script Reference

| File | Responsibility |
|------|---------------|
| `.claude/hooks/pre_tool_use.sh` | Blocks forbidden tool calls based on `.workflow_state` |
| `.claude/hooks/post_tool_use.sh` | Records tool activity for inspection |
| `.claude/hooks/stop.sh` | Reminds agent to update `PROMPTS.md` |
| `scripts/advance_state.sh` | Enforces valid state transitions |
| `scripts/verify.sh` | Runs all deterministic verification checks |

Hooks enforce **tool execution** only — they cannot control model reasoning. AGENTS.md governs model behavior; hooks enforce it mechanically where possible.
