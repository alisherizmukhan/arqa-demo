#!/usr/bin/env bash
# .railway/railway.ts must keep login on: production runs AUTH_REQUIRED=true
# since 2026-10-12, and `railway config apply` with any other value would
# switch it off (docs/AI_NOTES.md, maps stage 1).
set -euo pipefail
cd "$(dirname "$0")/.."
file=.railway/railway.ts
# Declarations only, not comments.
lines=$(grep -nE '^[^/]*\bAUTH_REQUIRED\b' "$file" || true)
if [ -z "$lines" ]; then
  echo "$file: AUTH_REQUIRED is not declared (must be \"true\")" >&2
  exit 1
fi
bad=$(printf '%s\n' "$lines" | grep -vE '^[0-9]+:\s*AUTH_REQUIRED:\s*"true",?\s*$' || true)
if [ -n "$bad" ]; then
  echo "$file: AUTH_REQUIRED must be \"true\":" >&2
  printf '%s\n' "$bad" >&2
  exit 1
fi
echo "$file: AUTH_REQUIRED is \"true\""
