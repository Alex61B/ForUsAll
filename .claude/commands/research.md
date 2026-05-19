# /research — RESEARCH State Command

You are now in the **RESEARCH** workflow state. Read `AGENTS.md` for the authoritative rules. This command defines your operational mandate for this state.

---

## Purpose

Understand all project requirements, identify technical risks, and justify stack choices. You produce knowledge only — no code, no files, no commands that modify the project.

## Current State Check

Before proceeding, confirm:
```bash
cat .workflow_state   # must print: RESEARCH
```
If the state is not RESEARCH, stop and notify the user. Do not proceed in the wrong state.

---

## Allowed Actions

- Read `Task.md`, `AGENTS.md`, and any existing project files
- Search documentation and web resources
- Ask clarifying questions
- Analyze requirements, constraints, and business rules
- List technical risks and open questions
- Choose and justify the technology stack

---

## Forbidden Actions

You **must not** do any of the following in RESEARCH state. The `pre_tool_use` hook will block these:

- Write any files under `app/`, `db/`, `spec/`, `lib/`, `config/`, or `Gemfile`
- Run `rails generate`, `rails new`, `bundle install`, `rake db:*`, `rspec`, or `rubocop`
- Create migrations, models, controllers, seeds, or specs
- Advance state until exit criteria are fully met

If the hook blocks an action, narrow your behavior to the failing requirement and do not attempt to bypass the gate.

---

## Required Outputs

Produce the following in your response before advancing:

1. **Functional requirements list** — every feature from `Task.md`, structured by area
2. **Technical risks** — at least 3 specific risks with mitigations (e.g., overlapping requests, annual limits, manager hierarchy validation)
3. **Stack justification** — chosen gems/tools with brief rationale for each
4. **Open questions** — anything ambiguous that must be resolved in PLAN

---

## Exit Criteria (backpressure gate)

All of the following must be true before you call `scripts/advance_state.sh next`:

- [ ] All functional requirements from `Task.md` are listed
- [ ] Technical risks are identified and noted
- [ ] Stack choices are justified
- [ ] Open questions are listed or resolved
- [ ] Research prompt(s) are logged in `PROMPTS.md`

Once all criteria are met:
```bash
bash scripts/advance_state.sh next
# Output: → State: RESEARCH → PLAN
```

---

## Failure Behavior

If you cannot satisfy exit criteria (e.g., requirements are ambiguous, a risk has no viable mitigation), **stop and ask the user** before advancing. Do not proceed with unresolved blockers.
