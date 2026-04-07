#!/usr/bin/env bash
set -euo pipefail

# Try local monorepo CLI first (for development), then fall back to npx.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MONOREPO_CLI="$SCRIPT_DIR/../../../packages/cli/dist/index.js"

if [ -f "$MONOREPO_CLI" ]; then
  exec node "$MONOREPO_CLI" login "$@"
else
  exec npx --yes @workjournal/cli login "$@"
fi
