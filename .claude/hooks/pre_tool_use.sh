#!/usr/bin/env bash
# pre_tool_use.sh — Enforces workflow state boundaries before tool execution.
#
# Receives tool call JSON on stdin (Claude Code hook protocol).
# Exit 0 = allow the tool call.
# Exit 2 = block the tool call; stdout is returned to the model as a rejection message.
#
# IMPORTANT LIMITS: This hook enforces tool *execution* only. It cannot control
# model reasoning or multi-step plans. AGENTS.md governs model behavior; this
# script is the mechanical enforcement layer for Write, Edit, and Bash calls.
#
# Protected state files (.workflow_state, .workflow_failures):
#   These may NEVER be written via the Write/Edit tool. Only advance_state.sh writes them.
#
# State files:
#   .workflow_state      — current state: RESEARCH | PLAN | IMPLEMENT | TEST
#   .workflow_failures   — remediation loop count
#   .workflow_plan_files — planned file manifest (written during PLAN state)
#   .workflow_drift      — set by post_tool_use.sh when unplanned files are detected

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
STATE_FILE="$PROJECT_ROOT/.workflow_state"
PLAN_FILES="$PROJECT_ROOT/.workflow_plan_files"
DRIFT_FLAG="$PROJECT_ROOT/.workflow_drift"

STATE=$(cat "$STATE_FILE" 2>/dev/null | tr -d '[:space:]' || echo "RESEARCH")

# Read stdin JSON (consumed once; subsequent calls re-parse from variable)
INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_name', ''))
except Exception:
    print('')
" 2>/dev/null || true)

# ─── Helpers ────────────────────────────────────────────────────────────────

# Returns 0 if the path is a Rails application file that should be gated.
is_app_file() {
  local p="$1"
  p="${p#"$PROJECT_ROOT"/}"
  p="${p#./}"
  case "$p" in
    app/*|db/*|spec/*|lib/*|config/*|Gemfile|Gemfile.lock|test/*)
      return 0 ;;
    *)
      return 1 ;;
  esac
}

# Returns 0 if the path is a workflow/planning file always allowed for writing.
# NOTE: .workflow_state and .workflow_failures are intentionally excluded here —
# they are protected by is_protected_state_file() below.
is_planning_file() {
  local p="$1"
  p="${p#"$PROJECT_ROOT"/}"
  p="${p#./}"
  case "$p" in
    .workflow_plan_files|.workflow_activity|.workflow_drift)
      return 0 ;;
    AGENTS.md|PROMPTS.md|README.md|docs/*|.claude/*|scripts/*|*.md)
      return 0 ;;
    *)
      return 1 ;;
  esac
}

# Returns 0 if the path is a workflow control file managed exclusively by advance_state.sh.
# These are NEVER writable via the Write/Edit tool — in any state.
is_protected_state_file() {
  local p="$1"
  p="${p#"$PROJECT_ROOT"/}"
  p="${p#./}"
  case "$p" in
    .workflow_state|.workflow_failures)
      return 0 ;;
    *)
      return 1 ;;
  esac
}

# Returns 0 if the path is listed in .workflow_plan_files (exact full-line match).
is_planned_file() {
  local p="$1"
  p="${p#"$PROJECT_ROOT"/}"
  p="${p#./}"
  [[ -f "$PLAN_FILES" ]] && grep -qxF "$p" "$PLAN_FILES" 2>/dev/null
}

# Returns 0 if the bash command contains implementation operations blocked in RESEARCH/PLAN.
# Checks two categories:
#   1. Named Rails/Bundler commands
#   2. Shell redirects targeting tracked application directories
is_impl_command() {
  local cmd="$1"

  # Named implementation commands
  if echo "$cmd" | grep -qE \
    '(rails[[:space:]]+(g|generate|new|db:|server|console)|bin\/rails[[:space:]]+(g|generate|db:)|\./bin\/rails[[:space:]]+(g|generate|db:)|bundle[[:space:]]+exec[[:space:]]+rails[[:space:]]+(g|generate|db:)|rake[[:space:]]+db:|bundle[[:space:]]+(install|add)|rspec|bundle[[:space:]]+exec[[:space:]]+rspec|rubocop|bundle[[:space:]]+exec[[:space:]]+rubocop)' \
    2>/dev/null; then
    return 0
  fi

  # Shell redirects to application paths (catches: printf/echo/cat/tee writing to app/ etc.)
  if echo "$cmd" | grep -qE \
    '(>>?|[[:space:]]tee[[:space:]])[[:space:]]*("|'"'"')?(app|db|spec|lib|config|test)\/' \
    2>/dev/null; then
    return 0
  fi

  return 1
}

# ─── Drift check ─────────────────────────────────────────────────────────────
# Called at the start of any IMPLEMENT-state tool dispatch.
# If .workflow_drift exists, all further work is blocked until drift is resolved.

check_drift_flag() {
  if [[ -f "$DRIFT_FLAG" ]]; then
    echo "BLOCKED [IMPLEMENT state]: Unplanned files were detected. Resolve drift before continuing."
    echo ""
    echo "Unplanned files:"
    sed 's/^/  /' "$DRIFT_FLAG" 2>/dev/null || echo "  (see .workflow_drift)"
    echo ""
    echo "Recovery options:"
    echo "  1. Delete each unplanned file and run: rm .workflow_drift"
    echo "     Then continue working in IMPLEMENT."
    echo "  2. bash scripts/advance_state.sh drift-to-plan"
    echo "     Return to PLAN to add the files to .workflow_plan_files."
    echo "  3. bash scripts/advance_state.sh drift-to-research"
    echo "     Return to RESEARCH if requirements or environment assumptions were wrong."
    exit 2
  fi
}

# ─── File write enforcement (Write and Edit tools) ───────────────────────────

check_file_write() {
  local file_path="$1"
  [[ -z "$file_path" ]] && return 0

  # Unconditional block: state control files are off-limits to direct writes in all states
  if is_protected_state_file "$file_path"; then
    echo "BLOCKED: '$file_path' is a protected workflow control file."
    echo ""
    echo ".workflow_state and .workflow_failures are managed exclusively by scripts/advance_state.sh."
    echo "Direct writes are blocked in all workflow states."
    echo ""
    echo "To change workflow state, use:"
    echo "  bash scripts/advance_state.sh next         (forward transition)"
    echo "  bash scripts/advance_state.sh fail         (TEST failure → RESEARCH)"
    echo "  bash scripts/advance_state.sh drift-to-plan     (drift recovery → PLAN)"
    echo "  bash scripts/advance_state.sh drift-to-research (drift recovery → RESEARCH)"
    exit 2
  fi

  case "$STATE" in
    RESEARCH)
      if is_app_file "$file_path" && ! is_planning_file "$file_path"; then
        echo "BLOCKED [RESEARCH state]: Writing application files is forbidden."
        echo "File: $file_path"
        echo ""
        echo "Allowed: read files, research requirements, update docs/, AGENTS.md, PROMPTS.md."
        echo "To advance: create docs/research.md with all required sections,"
        echo "  log research prompt in PROMPTS.md, then: bash scripts/advance_state.sh next"
        exit 2
      fi
      ;;

    PLAN)
      if is_app_file "$file_path" && ! is_planning_file "$file_path"; then
        echo "BLOCKED [PLAN state]: Writing application code is forbidden during PLAN."
        echo "File: $file_path"
        echo ""
        echo "Allowed: .workflow_plan_files, AGENTS.md, PROMPTS.md, docs/, scripts/, *.md"
        echo "To advance: complete .workflow_plan_files manifest, then: bash scripts/advance_state.sh next"
        exit 2
      fi
      ;;

    IMPLEMENT)
      check_drift_flag
      if is_app_file "$file_path" && ! is_planned_file "$file_path"; then
        echo "BLOCKED [IMPLEMENT state]: '$file_path' is not in .workflow_plan_files."
        echo ""
        echo "Only files listed in .workflow_plan_files may be written during IMPLEMENT."
        if [[ -f "$PLAN_FILES" ]]; then
          echo ""
          echo "Current manifest (.workflow_plan_files):"
          cat "$PLAN_FILES"
        fi
        echo ""
        echo "To add this file to the plan: edit .workflow_plan_files (add path on its own line)."
        exit 2
      fi
      ;;

    TEST)
      if is_app_file "$file_path" && ! is_planning_file "$file_path"; then
        echo "BLOCKED [TEST state]: Do not modify application files while verification is running."
        echo "File: $file_path"
        echo ""
        echo "Run 'bash scripts/verify.sh' first. If all checks pass, advance state."
        echo "If checks fail: bash scripts/advance_state.sh fail"
        exit 2
      fi
      ;;
  esac
}

# ─── Bash command enforcement ────────────────────────────────────────────────

check_bash_command() {
  local cmd="$1"
  [[ -z "$cmd" ]] && return 0

  # Unconditional block: protect state control files from shell redirects in all states
  if echo "$cmd" | grep -qE '(>>?|[[:space:]]tee[[:space:]])[[:space:]]*\.workflow_(state|failures)' 2>/dev/null; then
    echo "BLOCKED: Cannot write to protected state file via shell redirect."
    echo "Command: $cmd"
    echo ""
    echo ".workflow_state and .workflow_failures are managed only by scripts/advance_state.sh."
    exit 2
  fi

  case "$STATE" in
    RESEARCH|PLAN)
      if is_impl_command "$cmd"; then
        echo "BLOCKED [$STATE state]: Implementation commands are forbidden in $STATE state."
        echo "Command: $cmd"
        echo ""
        echo "Blocked: rails generate, rails new, rails db:*, bin/rails generate,"
        echo "  bundle install, bundle add, rake db:*, rspec, rubocop,"
        echo "  and shell redirects (>, >>, tee) targeting app/db/spec/lib/config paths."
        echo ""
        echo "Complete $STATE work, satisfy exit criteria, then advance:"
        echo "  bash scripts/advance_state.sh next"
        exit 2
      fi
      ;;

    IMPLEMENT)
      check_drift_flag
      ;;
    # TEST: allow Bash freely (verify.sh, rspec, routes inspection)
  esac
}

# ─── Dispatch by tool name ───────────────────────────────────────────────────

case "$TOOL_NAME" in
  Write)
    FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('file_path', ''))
except Exception:
    print('')
" 2>/dev/null || true)
    check_file_write "$FILE_PATH"
    ;;

  Edit)
    FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('file_path', ''))
except Exception:
    print('')
" 2>/dev/null || true)
    check_file_write "$FILE_PATH"
    ;;

  Bash)
    COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('command', ''))
except Exception:
    print('')
" 2>/dev/null || true)
    check_bash_command "$COMMAND"
    ;;
esac

exit 0
