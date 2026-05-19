# Employee Time-Off Tracking System

## Project Overview & Architecture

Rails 8 + PostgreSQL application for managing employee time-off requests with
role-based approval workflows. Exposes JSON:API compliant REST endpoints with
server-rendered HTML views (no React/Vue).

**Roles:** Employee → Manager → Admin. Managers approve direct reports;
Admins manage all requests.

**Stack:** Rails 8, PostgreSQL, Devise (auth), RSpec, ActiveJob (notifications),
Bootstrap (styling), JSON:API serializers.

**Directory structure:**
```
app/          # Models, controllers, views, jobs, mailers, serializers
config/       # Routes, database, initializers
db/           # Migrations, schema, seeds
spec/         # RSpec tests (models, requests, features, mailers)
lib/          # Custom modules only if needed
docs/         # API docs, research.md, planning artifacts
scripts/      # Workflow state management (do not edit)
.claude/      # Agents, hooks, commands, settings (do not edit hooks)
```

See [AGENTS.md](AGENTS.md) for the complete workflow specification.

---

## Key Commands

```bash
# Development
bin/rails server                          # Start server (localhost:3000)
bin/rails db:create db:migrate db:seed    # Full DB setup
bin/rails db:migrate                      # Run pending migrations
bin/rails routes                          # List all routes

# Workflow state
cat .workflow_state                       # Check current state
bash scripts/advance_state.sh next        # Advance to next state (gated)
bash scripts/advance_state.sh fail        # Mark test failure → returns to RESEARCH

# Verification (run before advancing from TEST)
bash scripts/verify.sh                    # Full suite: db + rspec + routes + rubocop

# Individual checks
bundle exec rspec                         # All specs
bundle exec rails db:prepare              # Ensure DB is current
bundle exec rubocop --no-color            # Lint (if .rubocop.yml exists)
```

---

## Workflow Expectations

This project enforces **RESEARCH → PLAN → IMPLEMENT → TEST** with hard gates.

| State | Purpose | Forbidden |
|-------|---------|-----------|
| RESEARCH | Understand requirements, identify risks | Write app code |
| PLAN | Define schema, routes, acceptance criteria | Write app code |
| IMPLEMENT | Build exactly what `.workflow_plan_files` lists | Unplanned files |
| TEST | Run `verify.sh`, fix only failing checks | New features |

- State transitions require `bash scripts/advance_state.sh next` — it verifies exit criteria.
- Every development prompt must be logged in `PROMPTS.md` before advancing state.
- Hooks in `.claude/hooks/` enforce state boundaries mechanically — do not bypass.

---

## State Discipline & Backpressure Rules

- **Do not advance state** until all exit criteria pass the `advance_state.sh` gate.
- **Do not write files not listed** in `.workflow_plan_files` during IMPLEMENT — triggers `.workflow_drift`.
- **Do not add unplanned features** — surface new requirements in RESEARCH.
- **Do not refactor unrelated code** during IMPLEMENT or TEST.
- **Remediation scope is narrow**: TEST failures return to RESEARCH for the specific failing item only.
- **Max 3 remediation loops**: `advance_state.sh fail` increments `.workflow_failures`; at 3, full review required.
- **Drift recovery**: Delete unplanned files + `rm .workflow_drift`, or use `advance_state.sh drift-to-plan`.

---

## Rails/Ruby Standards

- Controllers: params, auth check, call model/service, render/redirect — nothing else.
- Use `strong_parameters` in every controller action that accepts input.
- Prefer Rails scopes over class methods for named queries.
- Keep methods under 20 lines; extract only when complexity demands it.
- Use `before_action` for authentication; authorize within actions or via a policy object.
- No service objects unless a controller or model exceeds clear responsibility boundaries.
- No raw SQL — use ActiveRecord. Exception: complex reporting queries with documented rationale.
- Follow Rails naming: plural controllers, singular models, snake_case everywhere.

---

## Verification Requirements

All checks must pass before `TEST → done`:

| Check | Command | Passes When |
|-------|---------|-------------|
| Database | `bundle exec rails db:prepare` | Exit 0 |
| Specs | `bundle exec rspec` | Exit 0, 0 failures |
| Routes | `bundle exec rails routes` | ≥1 route printed |
| Linting | `bundle exec rubocop --no-color` | Exit 0 (if `.rubocop.yml` present) |

- `scripts/verify.sh` runs all four in sequence (fail-fast). Use it.
- Never mark work complete while any check is failing.
- On failure: identify the specific blocker, remediate only that item, rerun.

---

## Prompt Logging Expectations

Every development prompt must be appended to `PROMPTS.md`:

```markdown
### Prompt #N — [STATE] State
**Date**: YYYY-MM-DD
**Tool**: Claude Code
**State**: RESEARCH | PLAN | IMPLEMENT | TEST
**Prompt**: > verbatim prompt text
**Output Summary**: What was produced
**Files Changed**: path/to/file.rb, or "none"
**Verification**: passed | failed | not applicable
```

- `stop.sh` hook and `advance_state.sh` both verify prompt counts. No omissions.
- Log the prompt entry **before** calling `advance_state.sh next`.
