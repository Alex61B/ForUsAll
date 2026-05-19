*PROMPT SECTION1*
Follow the goals. Keep the system lightweight and inspectable. Avoid overengineering, complex orchestration frameworks, or unnecessary abstraction. Prefer simple deterministic enforcement mechanisms.

This prompt initializes the workflow/control system only. The Rails application implementation will occur in later prompts.

Goal1: Create the initial AGENTS.md file (first step in agentic workflow foundation “backpressure system”) for Rails project.

Create AGENTS.md with following sections:
Project Context: Concisely state this project uses backpressure agentic workflow to build Rails 8 employee time-off tracking system 
Official/required workflow: Research → Plan → Implement → Test (each of the 4 are considered a workflow state)
Backpressure definition: agent cannot advance to next workflow state until current state satisfies deterministic exit criteria. 
If a gate fails → agent must narrow its behavior to the failing requirement, test, or verification issue.
While verification is failing, agent is restricted to narrow corrective actions related only to the failing requirement, test, or verification step.
State Machine: Define allowed transitions 
Research → Plan 
Plan → Implement
Implement → Test 
Failure behavior: 
Test → Research, only if verification fails
Agent enters a constrained remediation loop mirroring: Research → Plan → Implement → Test
The remediation loop scope is restricted only to the failing requirement, test, or verification issue.
State Gates: for each workflow state, define 
Purpose 
Allowed actions
Forbidden actions
Exit criteria 
State 1: Research: 
Allowed: inspect requirements and environment, identify risks, choose stack
Forbidden: write application code
Exit: requirements understood, risks listed, stack choices justified
State 2: Plan:
Allowed: define architecture, models, routes, tests, files to change
Forbidden: writing implementation code
Exit: concrete implementation checklist and acceptance criteria exist
State 3: Implement:
Allowed: change only planned files, write app code, specs, docs, seeds
Forbidden: unrelated (to plan) refactors, new unplanned features
Exit: implementation matches plan and is ready for verification
State 4: Test:
Allowed: run deterministic checks, report failures, verify requirements
Forbidden: adding new features while failing
Exit: tests pass, migrations work, routes exist, docs and prompt log are updated
Failure Behavior: include the following
If tests fail → agent enter a constrained remediation loop mirroring this flow—Research → Plan → Implement → Test—for the failure, only targeting the failing check
No new feature work is allowed while verification is failing
If the same failure repeats three times, stop and summarize the blocker 
Prompt Logging Rule:
Create a PROMPTS.md template containing:  
Every prompt used during development (required, no exceptions)
The tool used (e.g., Cursor, Copilot, Claude)  
Resulting outputs  
A clearly labeled example demonstrating your agentic one-shot approach with back pressure

Goal 2: Create claude command files
.claude/commands/research.md
.claude/commands/plan.md
.claude/commands/implement.md
.claude/commands/test.md
Command files should:
define allowed/disallowed behavior for each workflow state
define required outputs and exit criteria
reinforce deterministic backpressure principles
reinforce constrained remediation loops during failures
enforce workflow state boundaries
keep behavior concise, operational, and workflow-centric


Goal 3: Create hooks / scripts for deterministic gates
.claude/hooks/*
scripts/verify.sh
Hooks should:
enforce lightweight workflow discipline
enforce verification before completion
encourage prompt logging compliance
prevent workflow advancement while verification is failing
reinforce deterministic backpressure behavior
remain simple and inspectable (avoid overengineering)
scripts/verify.sh should:
run database preparation/migrations
run RSpec
print routes
run RuboCop if configured
fail immediately on verification failure

Implement lightweight mechanical enforcement using external workflow state.

To enforce agent actions
Create:
.workflow_state initialized to RESEARCH
.workflow_failures initialized to 0
scripts/advance_state.sh
scripts/verify.sh
.claude/hooks/pre_tool_use.sh
.claude/hooks/post_tool_use.sh
.claude/hooks/stop.sh
Rules:
AGENTS.md remains the source of truth.
Hooks should read .workflow_state before allowing actions.
RESEARCH and PLAN must block application file writes.
IMPLEMENT may edit only planned files when possible.
TEST may run verification but not add new features.
State transitions must go through scripts/advance_state.sh.
Failed verification should keep or return the workflow to a constrained remediation loop.
After three repeated failures, stop and summarize the blocker.
Keep hooks simple, inspectable, and conservative.
Add comments explaining limits: hooks enforce tool actions, not model reasoning.
pre_tool_use.sh must parse stdin JSON to extract the command or file path being written, not just check the tool name. The bash tool must be inspected for implementation commands regardless of state.
Plan state must write intended files to .workflow_plan_files (one per line). Implement state hook must validate file writes against this manifest and block unplanned writes.


Constraints 
Only create AGENTS.md, .claude/commands/*, .claude/hooks/*, scripts/verify.sh, PROMPTS.md template
Do not modify CLAUDE.md or create specialized agents/subagents yet.


*PROMPT SECTION2*
PROMPT 1
After completing the workflow enforcement setup, explain how mechanical enforcement actually works in this system. Cover:

What is genuinely hard-blocked (tool calls, file writes, state transitions) and exactly how each block works mechanically
How exit criteria are enforced — is Claude checking them, or is advance_state.sh checking them, and what's the difference
What remains soft — where Claude is relying on instruction/reasoning rather than a hard block
Specifically: how does Claude "know" it's satisfied exit criteria before attempting advance_state.sh? Is that mechanical or behavioral?
Any gaps where the enforcement layer has no coverage

Be honest about limits. Distinguish between "blocked at the tool level" vs "enforced by instruction" vs "not enforced at all."

PROMPT 1.5 – CLAUDE
when should research move to plan?
i think if
- docs/research.md exists
- requirements have been summarized
- stack choices are documented
- major risks/edge cases are listed
- assumptions/open questions are listed
- readiness verdict says ready for planning
- PROMPTS.md has been updated
anything else?


PROMPT 2
fix those identified gaps. if unplanned files are created then stop immediately, summarize the drift, revered the unplanned files and return to plan to update, return to research if the dirft reveals misunderstood requirements or environment assumptions. Do not create Rails application code.
1. Protect workflow control files
2. Strengthen Bash enforcement
3. Add hard state-transition gates in scripts/advance_state.sh
4. Add RESEARCH exit criteria
docs/research.md must contain:
- Requirements Summary
- Stack Choices
- Environment Verification
- Risks & Edge Cases
- Assumptions & Open Questions
- Out of Scope
- Readiness Verdict: READY FOR PLANNING
advance_state.sh should grep for these sections before allowing RESEARCH → PLAN.
5. Improve prompt logging enforcement
6. Add drift handling
- If unplanned files are detected, stop and summarize the drift
- Allow recovery by reverting/deleting files or returning to PLAN to update .workflow_plan_files
- Return to RESEARCH only if requirements/environment assumptions were wrong
After patching, run manual verification proving:
- direct write to .workflow_state is blocked
- RESEARCH cannot advance without valid docs/research.md
- Bash writes to app/ paths are blocked in RESEARCH/PLAN
- PLAN cannot advance without .workflow_plan_files
- IMPLEMENT blocks unplanned writes
- TEST cannot complete unless scripts/verify.sh passes
Update PROMPTS.md with this prompt and verification results.

*PROMPT SECITION 3*
Use the following project requirements to create CLAUDE.md and specialized agents/subagents. The agents/subagents should complement the workflow system defined in AGENTS.md and the workflow enforcement layer defined in .claude/commands/*.
Core Features  
1. **Employee Management**  
   - Employees can register/login  
   - Basic profile (name, email, department, manager)  
   - Role-based access (Employee, Manager, Admin)  

2. **Time-Off Requests**  
   - Submit time-off requests (vacation, sick leave, personal)  
   - Specify date ranges and reason  
   - Track request status (pending, approved, denied)  
   - View request history  

3. **Approval Workflow**  
   - Managers approve/deny requests for direct reports  
   - Admins manage all requests  
   - Email notifications for status changes (mock or background job based)  

4. **API & Frontend**  
   - JSON:API compliant REST endpoints  
   - Simple HTML interface using Rails views (no React/Vue required)  
   - Basic styling with CSS/Bootstrap  

Constraints
Do not create any rails application code, models, controllers, migrations, routes, views, specs, or frontend implementation yet.

Goal 4: Create CLAUDE.md file:
Keep the file concise (max 150 lines), practical, and operational; it should reinforce the deterministic backpressure system defined in AGENTS.md.
Include the following sections:
Project Overview & Architecture
concise description of the Rails 8 employee time-off tracking system
brief repository/directory structure overview
high-level architecture expectations
Key Commands
Include commonly used development and verification commands:
Rails server
database setup/migrations
RSpec
RuboCop
verification script(s)
Workflow Expectations
reinforce Research → Plan → Implement → Test workflow
require deterministic verification before work is considered complete
require respecting workflow state boundaries
require concise implementation summaries after major changes
State Discipline & Backpressure Rules
prohibit advancing workflow states before exit criteria are satisfied
prohibit unrelated refactors
prohibit speculative/unplanned features
require constrained remediation loops during failures
require remediation scope to stay limited to the failing requirement, test, or verification issue
 Rails/Ruby Standards
maintain readable, production-oriented Rails code
prefer Rails conventions over unnecessary abstraction
keep controllers thin
use strong parameters
write readable RSpec tests
prefer small focused methods/files when practical
Verification Requirements
require tests, migrations, routes, and linting verification before completion
prohibit completion while verification is failing
require verification summaries and blocker reporting
Prompt Logging Expectations
every development prompt must be logged in PROMPTS.md
include tool used, outputs, files changed, and verification result
no prompt omissions allowed

Goal 5: Add agents/subagents/skills only if they help
Keep concise/ don’t overcomplicate. Suggested agents:
Rails Architect - responsible for application architecture, schema design, routes, and service boundaries
Rails Implementer - responsible for Rails implementation, models, controllers, migrations, views, and API behavior
Test/QA Agent - responsible for RSpec coverage, edge cases, regression prevention, and requirement verification
Security/Auth Reviewer - responsible for authentication, authorization, role boundaries, and permission/security review

Constraints
Only create: CLAUDE.md and .claude/agents/*
Do not create any rails application code, models, controllers, migrations, routes, views, specs, or frontend implementation yet.


*PROMPT SECITON 4*
Begin building the Rails employee time-off tracking app using the workflow system already defined in AGENTS.md.
Start in Research State using the workflow: Research → Plan → Implement → Test
Use the existing hooks, scripts, .workflow_state, .workflow_plan_files, and PROMPTS.md requirements. Do not bypass advance_state.sh.
Project Requirements:
1. **Employee Management**  
   - Employees can register/login  
   - Basic profile (name, email, department, manager)  
   - Role-based access (Employee, Manager, Admin)  
2. **Time-Off Requests**  
   - Submit time-off requests (vacation, sick leave, personal)  
   - Specify date ranges and reason  
   - Track request status (pending, approved, denied)  
   - View request history  
3. **Approval Workflow**  
   - Managers approve/deny requests for direct reports  
   - Admins manage all requests  
   - Email notifications for status changes (mock or background job based)  
4. **API & Frontend**  
   - JSON:API compliant REST endpoints  
   - Simple HTML interface using Rails views (no React/Vue required)  
   - Basic styling with CSS/Bootstrap  

Technical Requirments:
- Rails 8+
- PostgreSQL
- Devise or simple session auth; prefer Devise unless environment makes it impractical
- RSpec model/request tests
- ActiveJob notification mock
- Rails validations and business rules
- API docs in docs/api.md
- README with setup, tradeoffs, AI workflow, and prompt log link
Business Rules:
- Cannot request time off in the past
- End date must be on/after start date
- Flag or prevent overlapping pending/approved requests
- Annual vacation limit should be enforced with a simple configurable default
- Employees can only manage their own requests
- Managers can only review direct reports
- Admins can review everything
- Approval/denial should create an audit record

Output requirements summary, stack choices, out of scope, etc and update prompts accordingly; verify Research exit criteria; advance workflow state





