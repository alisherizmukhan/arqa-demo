#!/usr/bin/env bash
# Regenerates the alchemist CI goldens (text drawn as blocks) on Linux, the
# platform GitHub Actions compares them on. Windows/macOS layout metrics differ
# slightly, so CI goldens must not be generated on a developer machine.
#
#   tool/update_ci_goldens.sh [package-dir ...]   (default: packages/design_kit)
#
# Needs Docker. Flutter 3.47.6 is cached in the `flutter-3.47.6` volume.
set -euo pipefail
cd "$(dirname "$0")/.."
packages=("${@:-packages/design_kit}")

MSYS_NO_PATHCONV=1 docker run --rm \
  -v "$(pwd):/src" \
  -v flutter-3.47.6:/flutter \
  ubuntu:24.04 bash -c '
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null
apt-get install -y -qq git curl unzip xz-utils ca-certificates >/dev/null
git config --global --add safe.directory "*"
[ -x /flutter/bin/flutter ] || git clone -q --depth 1 -b 3.47.6 \
  https://github.com/flutter/flutter.git /flutter
export PATH=/flutter/bin:$PATH CI=true
mkdir /work
tar -C /src --exclude=.dart_tool --exclude=build --exclude=.venv \
  --exclude=node_modules -cf - . | tar -C /work -xf -
cd /work && flutter pub get --enforce-lockfile >/dev/null
for pkg in '"${packages[*]}"'; do
  (cd "$pkg" && flutter test --update-goldens >/dev/null)
  find "$pkg" -path "*/goldens/ci/*.png" | while read -r f; do
    mkdir -p "/src/$(dirname "$f")" && cp "$f" "/src/$f"
  done
  echo "updated CI goldens in $pkg"
done
'
