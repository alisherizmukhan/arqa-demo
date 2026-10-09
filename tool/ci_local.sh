#!/usr/bin/env bash
# Runs the CI steps of .github/workflows/ci.yml locally, in the same order,
# before a push to main (docs/AI_NOTES.md: a grep step once broke CI that the
# analyzer and tests alone did not catch).
#
#   tool/ci_local.sh            # everything
#   tool/ci_local.sh flutter    # skip the backend
#
# The backend tests need the docker-compose Postgres (TEST_DATABASE_URL).
# CI goldens are compared on Linux only; locally the platform goldens run.
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C.UTF-8

step() { printf '\n== %s\n' "$*"; }

if [ "${1:-}" != "flutter" ]; then
  step "backend: format, lint, types, tests"
  if [ -x backend/.venv/Scripts/python ]; then run=(.venv/Scripts/python -m)
  elif [ -x backend/.venv/bin/python ]; then run=(.venv/bin/python -m)
  else run=(uv run python -m); fi
  (cd backend && "${run[@]}" ruff format --check .)
  (cd backend && "${run[@]}" ruff check .)
  (cd backend && "${run[@]}" mypy)
  # Coverage needs coverage's C tracer (concurrency=greenlet); without it
  # (some Windows venvs) the tests still run, and CI checks the coverage.
  if (cd backend && "${run[@]}" coverage debug sys 2>/dev/null | grep -q 'CTracer: available'); then
    (cd backend && "${run[@]}" pytest -q --cov --cov-fail-under=95)
  else
    echo "(no CTracer here: tests without coverage; CI enforces 95 %)"
    (cd backend && "${run[@]}" pytest -q)
  fi
fi

step "design kit: analyze, format, tests, showcase"
flutter pub get --enforce-lockfile >/dev/null
flutter analyze --fatal-infos packages/design_kit
dart format --output=none --set-exit-if-changed packages/design_kit
(cd packages/design_kit && flutter test)
(cd packages/design_kit/example && flutter test)

step "mobile: generated code is up to date"
# Locally the tree may be dirty: compare before and after generating.
before=$(git status --porcelain -- apps/mobile; git diff -- apps/mobile | sha256sum)
(cd apps/mobile && dart run build_runner build >/dev/null && flutter gen-l10n >/dev/null)
after=$(git status --porcelain -- apps/mobile; git diff -- apps/mobile | sha256sum)
if [ "$before" != "$after" ]; then
  echo "generated code was stale: review and commit the regenerated files" >&2
  exit 1
fi

step "mobile: no raw colors or text styles"
if grep -RnE 'Color\(0x|\bColors\.|TextStyle\(' apps/mobile/lib; then exit 1; fi

step "mobile: no Cyrillic literals outside the localizations"
hits=$(grep -RnP '[\x{0400}-\x{04FF}]' apps/mobile/lib packages/design_kit/lib --include='*.dart' \
  | grep -v '^apps/mobile/lib/l10n/gen/' \
  | grep -vP '^[^:]+:\d+:\s*//' || true)
if [ -n "$hits" ]; then echo "$hits"; exit 1; fi

step "mobile: analyze, format, tests, screenshots"
flutter analyze --fatal-infos apps/mobile
dart format --output=none --set-exit-if-changed apps/mobile/lib apps/mobile/test
(cd apps/mobile && flutter test)
(cd apps/mobile && SCREENSHOTS_DIR=build/screens flutter test test/screens/screenshots_test.dart)

step "all CI steps passed"
