#!/bin/bash
# ──────────────────────────────────────────────────────────────
# Entrypoint for the Torn PDA dev container.
#
# Copies config stubs if they don't exist yet, runs flutter pub
# get, then hands off to whatever command was passed.
# ──────────────────────────────────────────────────────────────

set -e

# Config and Android stubs, only the missing ones
bash .github/ci_stubs.sh --android

# Install deps if pubspec exists and .dart_tool is missing
if [ -f "pubspec.yaml" ] && [ ! -d ".dart_tool" ]; then
  echo "Running flutter pub get..."
  flutter pub get
fi

exec "$@"
