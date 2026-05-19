#!/usr/bin/env bash
# verify.sh — Runs all deterministic verification checks for the Rails application.
#
# Sequence (fail-fast — stops on first failure):
#   1. bundle exec rails db:prepare   — run migrations and prepare schema
#   2. bundle exec rspec              — run all specs
#   3. bundle exec rails routes       — verify routes exist
#   4. bundle exec rubocop            — style checks (only if .rubocop.yml is present)
#
# On success: writes .workflow_verified (timestamp lock required by advance_state.sh TEST gate).
# On failure: removes .workflow_verified and exits 1.
#
# Run from the project root:
#   bash scripts/verify.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

VERIFIED_LOCK="$PROJECT_ROOT/.workflow_verified"
STATE=$(cat .workflow_state 2>/dev/null | tr -d '[:space:]' || echo "UNKNOWN")

# Always clear the lock at entry — a fresh run is always required
rm -f "$VERIFIED_LOCK" 2>/dev/null || true

echo "═══════════════════════════════════════════════════"
echo "  Workflow Verification Suite"
echo "  State: $STATE"
echo "  $(date)"
echo "═══════════════════════════════════════════════════"
echo ""

fail() {
  local check="$1"
  local hint="$2"
  echo ""
  echo "VERIFICATION FAILED: $check"
  echo "$hint"
  echo ""
  echo "Fix the failure, then re-run: bash scripts/verify.sh"
  echo "If this is a repeated failure: bash scripts/advance_state.sh fail"
  rm -f "$VERIFIED_LOCK" 2>/dev/null || true
  exit 1
}

# ─── 1. Database preparation ────────────────────────────────────────────────

echo "[ 1/4 ] Running db:prepare..."
if ! bundle exec rails db:prepare 2>&1; then
  fail "db:prepare failed" "Check database configuration and migration files."
fi
echo "        ✓ db:prepare succeeded"
echo ""

# ─── 2. RSpec ───────────────────────────────────────────────────────────────

echo "[ 2/4 ] Running RSpec..."
if ! bundle exec rspec --format progress 2>&1; then
  fail "RSpec reported failures" "Fix all failing specs before advancing."
fi
echo "        ✓ All specs passed"
echo ""

# ─── 3. Routes verification ─────────────────────────────────────────────────

echo "[ 3/4 ] Checking routes..."
ROUTES_OUTPUT=$(bundle exec rails routes 2>&1)
ROUTE_COUNT=$(echo "$ROUTES_OUTPUT" | grep -c "^" || true)
echo "$ROUTES_OUTPUT" | head -60
echo ""

if [[ "$ROUTE_COUNT" -le 1 ]]; then
  fail "No routes found" "Check config/routes.rb — expected employee, time-off, and auth routes."
fi
echo "        ✓ Routes verified ($ROUTE_COUNT lines)"
echo ""

# ─── 4. RuboCop (only if configured) ────────────────────────────────────────

if [[ -f "$PROJECT_ROOT/.rubocop.yml" ]]; then
  echo "[ 4/4 ] Running RuboCop..."
  if ! bundle exec rubocop --no-color 2>&1; then
    fail "RuboCop reported offenses" "Fix all offenses before advancing."
  fi
  echo "        ✓ RuboCop passed"
else
  echo "[ 4/4 ] Skipping RuboCop (.rubocop.yml not found)"
fi
echo ""

# ─── Write verification lock ────────────────────────────────────────────────

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")
echo "$TIMESTAMP" > "$VERIFIED_LOCK"

echo "═══════════════════════════════════════════════════"
echo "  All verification checks passed."
echo "  Lock written: .workflow_verified ($TIMESTAMP)"
echo ""
echo "  Remaining TEST exit criteria (manual):"
echo "    [ ] PROMPTS.md contains all development prompts"
echo "    [ ] docs/api.md (or Swagger spec) is present"
echo "    [ ] README.md has setup instructions"
echo ""
echo "  When complete: bash scripts/advance_state.sh next"
echo "═══════════════════════════════════════════════════"
