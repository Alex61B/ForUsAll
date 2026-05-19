# /test — TEST State Command

You are now in the **TEST** workflow state. Read `AGENTS.md` for the authoritative rules. This command defines your operational mandate for this state.

---

## Purpose

Run deterministic verification checks and confirm all requirements are met. This is the quality gate. You report failures precisely and trigger the remediation loop when needed.

## Current State Check

Before proceeding, confirm:
```bash
cat .workflow_state      # must print: TEST
cat .workflow_failures   # current remediation attempt count
```
If the state is not TEST, stop and notify the user.

---

## Allowed Actions

- Run `scripts/verify.sh` (the canonical verification suite)
- Run individual checks: `bundle exec rspec`, `bundle exec rails routes`, `bundle exec rubocop`
- Read test output and identify specific failures with file and line references
- Write **narrow corrective code only** for a currently failing check (remediation loop only)
- Update `PROMPTS.md` and `docs/api.md`

---

## Forbidden Actions

- Adding new features while any verification check is failing
- Changing test assertions to force a pass (fix the implementation, not the test)
- Advancing state (`scripts/advance_state.sh next`) while any check fails
- Opening new work items unrelated to the current failing check

---

## Verification Sequence

Run the full suite:
```bash
bash scripts/verify.sh
```

This runs in order (fail-fast):
1. `bundle exec rails db:prepare` — migrations and schema
2. `bundle exec rspec` — all specs
3. `bundle exec rails routes | head -60` — route verification
4. `bundle exec rubocop --no-color` — style checks (if `.rubocop.yml` present)

Report every failure with: check name, file path, line number, error message.

---

## On Failure: Constrained Remediation Loop

If any check fails:

1. Run `scripts/advance_state.sh fail` — returns to RESEARCH, increments `.workflow_failures`
2. **Scope is restricted**: address only the failing check. No new features.
3. Work through the mini-loop: RESEARCH (understand the failure) → PLAN (narrow fix) → IMPLEMENT (apply fix) → TEST (verify)
4. If `.workflow_failures` reaches 3, `advance_state.sh` will stop with a blocker summary prompt. Stop all changes and summarize the blocker for the user.

---

## Exit Criteria (backpressure gate)

All of the following must be true before calling `scripts/advance_state.sh next`:

- [ ] `bundle exec rspec` exits 0 (all specs pass, no pending)
- [ ] `bundle exec rails db:prepare` succeeds without errors
- [ ] `bundle exec rails routes` prints expected routes (auth, time-off, admin)
- [ ] RuboCop passes (if `.rubocop.yml` is configured)
- [ ] `docs/api.md` or Swagger spec is present and documents all endpoints
- [ ] `PROMPTS.md` contains every prompt used across all workflow states
- [ ] `README.md` includes setup instructions and AI-assistance notes

Once all criteria are met:
```bash
bash scripts/advance_state.sh next
# Output: → Workflow complete. Resetting to RESEARCH.
```

---

## Failure Behavior Summary

| Scenario | Action |
|----------|--------|
| Single check fails | `advance_state.sh fail` → remediation loop |
| Same failure 3 times | `advance_state.sh` exits 1 → stop, write blocker summary |
| New unrelated issue found | Log it, do not address it — finish current gate first |
