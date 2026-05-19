# /plan — PLAN State Command

You are now in the **PLAN** workflow state. Read `AGENTS.md` for the authoritative rules. This command defines your operational mandate for this state.

---

## Purpose

Produce a concrete, complete implementation checklist and acceptance criteria. You define what will be built and write the file manifest — but you do not write application code yet.

## Current State Check

Before proceeding, confirm:
```bash
cat .workflow_state   # must print: PLAN
```
If the state is not PLAN, stop and notify the user.

---

## Allowed Actions

- Define database schema: models, columns, data types, associations, validations
- Define API routes and controller action signatures (not implementations)
- Define business rules and edge cases
- Define RSpec test cases and acceptance criteria
- Write `.workflow_plan_files` — one planned relative file path per line (required)
- Write or update `AGENTS.md`, `PROMPTS.md`, `docs/`, `.claude/`, `scripts/`, `*.md` (root level)

---

## Forbidden Actions

The `pre_tool_use` hook will block these:

- Writing files to `app/`, `db/migrate/`, `spec/`, `lib/`, `config/routes.rb`, or `Gemfile`
- Running `rails generate`, `bundle install`, `rake db:*`, `rspec`, or `rubocop`
- Starting implementation of any feature
- Advancing state before `.workflow_plan_files` is complete

If the hook blocks an action, you are attempting implementation during planning. Return to defining the plan.

---

## Required Outputs

Before advancing, produce:

1. **`.workflow_plan_files`** — every file to be created or modified, one path per line:
   ```
   Gemfile
   config/routes.rb
   app/models/user.rb
   db/migrate/20260517000001_create_users.rb
   spec/models/user_spec.rb
   ...
   ```

2. **Database schema** — models with columns, types, indices, and associations

3. **Routes table** — method, path, controller#action for each endpoint

4. **Acceptance criteria** — one testable criterion per core feature requirement

5. **Background job strategy** — which jobs, when triggered, how tested

---

## Exit Criteria (backpressure gate)

All of the following must be true before calling `scripts/advance_state.sh next`:

- [ ] `.workflow_plan_files` exists and lists every file to be created or modified
- [ ] Every planned model has columns and associations defined
- [ ] Every core feature has at least one acceptance criterion
- [ ] API routes are fully defined
- [ ] Background job approach is specified
- [ ] Planning prompts are logged in `PROMPTS.md`

Once all criteria are met:
```bash
bash scripts/advance_state.sh next
# Output: → State: PLAN → IMPLEMENT
```

---

## Failure Behavior

If you realize during planning that research was incomplete (e.g., a requirement is ambiguous), do **not** advance. Return to RESEARCH by communicating the gap to the user. Do not invent requirements.
