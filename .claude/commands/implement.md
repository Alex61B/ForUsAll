# /implement — IMPLEMENT State Command

You are now in the **IMPLEMENT** workflow state. Read `AGENTS.md` for the authoritative rules. This command defines your operational mandate for this state.

---

## Purpose

Build the application exactly as planned. Every file you create or modify must appear in `.workflow_plan_files`. No scope creep, no unplanned refactors, no new features.

## Current State Check

Before proceeding, confirm:
```bash
cat .workflow_state        # must print: IMPLEMENT
cat .workflow_plan_files   # review the planned file list
```
If the state is not IMPLEMENT, stop and notify the user.

---

## Allowed Actions

- Create or edit any file listed in `.workflow_plan_files`
- Write models, controllers, views, routes, seeds, specs, and migrations
- Run `rails generate` when the output matches planned files
- Run `bundle install` to install planned gems
- Write API documentation and README sections

---

## Forbidden Actions

The `pre_tool_use` hook will block `Write`/`Edit` calls to unplanned files:

- Writing to files **not** listed in `.workflow_plan_files`
- Adding features not described in the plan
- Refactoring code unrelated to the current implementation plan
- Running `rspec`, `rubocop`, or `rails routes` to verify (that is TEST state)
- Advancing state before all planned files are implemented

If the hook blocks a Write call, either:
1. Add the file to `.workflow_plan_files` (if genuinely needed), or
2. Recognize you are going out of scope and stay within the plan

---

## Implementation Order (recommended)

1. `Gemfile` — add all gems
2. Database migrations and schema
3. Models (validations, associations, scopes)
4. Routes
5. Controllers and serializers
6. Views and layout
7. Background jobs and mailers
8. Seeds
9. RSpec specs (model, request, feature)
10. README and API docs

---

## Required Outputs

Before advancing, confirm:

1. Every file in `.workflow_plan_files` has been created
2. All planned models have validations, associations, and scopes implemented
3. All planned specs exist (they do not need to pass yet — TEST state verifies)
4. Seeds file generates a usable demo dataset
5. Application starts without errors (`rails server` would boot)

---

## Exit Criteria (backpressure gate)

All of the following must be true before calling `scripts/advance_state.sh next`:

- [ ] All files in `.workflow_plan_files` exist on disk
- [ ] No unimplemented stubs remain (no `raise NotImplementedError`, no empty controller actions)
- [ ] Seeds exist and load without errors
- [ ] Implementation prompts are logged in `PROMPTS.md`

Once all criteria are met:
```bash
bash scripts/advance_state.sh next
# Output: → State: IMPLEMENT → TEST
```

---

## Failure Behavior

If you discover a file is needed that was not planned, pause and evaluate:
- Is it essential? Add it to `.workflow_plan_files` and note the change.
- Is it a new feature? Do not add it — log the gap and continue with the original plan.

If a major planning gap is found, stop, communicate to the user, and do not advance state.
