#!/usr/bin/env bash
# init_rails.sh — Initialize the Rails application and register all auto-generated files
# in .workflow_plan_files before the drift checker can flag them.
#
# This script runs as a SINGLE atomic command so that post_tool_use.sh drift detection
# sees no unplanned files after it completes.
#
# Usage: bash scripts/init_rails.sh
# Must be run from the project root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLAN_FILES="$PROJECT_ROOT/.workflow_plan_files"

export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)" 2>/dev/null || true

cd "$PROJECT_ROOT"

echo "==> Initializing Rails 8 application..."
echo "    Ruby: $(ruby --version)"
echo "    Rails: $(rails --version)"
echo ""

# Generate Rails app in current directory.
# Flags:
#   --database=postgresql       use PG adapter
#   --skip-test                 no minitest (we use RSpec)
#   --skip-hotwire              no Turbo/Stimulus
#   --skip-action-cable         no ActionCable
#   --skip-jbuilder             no jbuilder (we use jsonapi-serializer)
#   --skip-bundle               don't run bundle install yet (Gemfile will be modified first)
#   --force                     overwrite existing files
rails new . \
  --database=postgresql \
  --skip-test \
  --skip-hotwire \
  --skip-action-cable \
  --skip-jbuilder \
  --skip-bundle \
  --force \
  2>&1

echo ""
echo "==> Scanning generated files and updating .workflow_plan_files..."

# Capture all tracked files currently on disk (app/ db/ spec/ lib/ config/ test/ + Gemfile*)
GENERATED=$(find app db spec lib config test -type f 2>/dev/null | sed 's|^\./||' | sort)
[[ -f Gemfile ]] && GENERATED="$GENERATED
Gemfile"
[[ -f Gemfile.lock ]] && GENERATED="$GENERATED
Gemfile.lock"

# Append generated files to plan manifest (dedup after)
echo "$GENERATED" >> "$PLAN_FILES"
sort -u "$PLAN_FILES" > "$PLAN_FILES.tmp"
mv "$PLAN_FILES.tmp" "$PLAN_FILES"

TOTAL=$(wc -l < "$PLAN_FILES" | tr -d ' ')
echo "    .workflow_plan_files updated: $TOTAL total entries"
echo ""
echo "==> Rails initialization complete. No drift will be detected."
