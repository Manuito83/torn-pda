#!/bin/bash
# ──────────────────────────────────────────────────────────────
# Entrypoint for the Torn PDA dev container.
#
# Copies config stubs if they don't exist yet, runs flutter pub
# get, then hands off to whatever command was passed.
# ──────────────────────────────────────────────────────────────

set -e

# Copy config stubs (only if they haven't been copied already)
if [ -d "lib/config" ]; then
  cd lib/config
  for f in *.dart.example; do
    [ -f "$f" ] && target="${f%.example}" && [ ! -f "$target" ] && cp "$f" "$target"
  done
  # firebase_options.dart lives one level up (lib/firebase_options.dart)
  [ -f firebase_options.dart.example ] && [ ! -f ../firebase_options.dart ] && \
    cp firebase_options.dart.example ../firebase_options.dart
  cd ../..
fi

if [ -d "lib/config" ]; then
  for f in auth/native_auth_models auth/native_auth_provider auth/native_user_provider auth/native_login_widget \
           chat/chat_engine chat/chat_push chat/torn_chat_source \
           stats/stats_controller stats/usage_counters stats/app_settings_daily; do
    target="lib/torn-pda-native/$f.dart"
    mkdir -p "$(dirname "$target")"
    if [ ! -f "$target" ]; then cp "lib/config/$(basename "$f").dart.example" "$target"; fi
  done
fi

# Env part file stub
[ -f lib/utils/env/env.g.dart.example ] && [ ! -f lib/utils/env/env.g.dart ] && \
  cp lib/utils/env/env.g.dart.example lib/utils/env/env.g.dart

# Android Firebase config stub
if [ -f "android/app/google-services.json.example" ] && [ ! -f "android/app/google-services.json" ]; then
  cp android/app/google-services.json.example android/app/google-services.json
fi

# Install deps if pubspec exists and .dart_tool is missing
if [ -f "pubspec.yaml" ] && [ ! -d ".dart_tool" ]; then
  echo "Running flutter pub get..."
  flutter pub get
fi

exec "$@"
