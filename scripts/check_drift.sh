#!/usr/bin/env bash
# check_drift.sh — Scans tracked directories for files not listed in .workflow_plan_files.
#
# Tracked scope: app/ db/ spec/ lib/ config/ test/ + Gemfile + Gemfile.lock
#
# Usage: bash scripts/check_drift.sh
# Exit 0 = no unplanned files found.
# Exit 1 = unplanned files exist (list printed to stdout, one path per line).
#
# Called by:
#   post_tool_use.sh  — after each Bash command in IMPLEMENT state
#   advance_state.sh  — final check before IMPLEMENT→TEST transition

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLAN_FILES="$PROJECT_ROOT/.workflow_plan_files"

cd "$PROJECT_ROOT"

# Collect all tracked files currently on disk
collect_tracked_files() {
  find app db spec lib config test -type f 2>/dev/null | sed 's|^\./||' | sort
  [[ -f Gemfile ]]      && echo "Gemfile"
  [[ -f Gemfile.lock ]] && echo "Gemfile.lock"
}

# If no plan manifest exists, any tracked files are unplanned
if [[ ! -f "$PLAN_FILES" ]]; then
  FOUND=$(collect_tracked_files)
  if [[ -n "$FOUND" ]]; then
    echo "$FOUND"
    exit 1
  fi
  exit 0
fi

DRIFT=()
while IFS= read -r filepath; do
  [[ -z "$filepath" ]] && continue
  rel="${filepath#./}"
  if ! grep -qxF "$rel" "$PLAN_FILES" 2>/dev/null; then
    DRIFT+=("$rel")
  fi
done < <(collect_tracked_files)

if [[ ${#DRIFT[@]} -gt 0 ]]; then
  printf '%s\n' "${DRIFT[@]}"
  exit 1
fi

exit 0
