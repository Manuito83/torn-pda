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

if [ -d "lib/torn-pda-native" ] || [ -d "lib/config" ]; then
  mkdir -p lib/torn-pda-native/auth lib/torn-pda-native/stats

  [ -f lib/config/native_auth_models.dart.example ] && \
    [ ! -f lib/torn-pda-native/auth/native_auth_models.dart ] && \
    cp lib/config/native_auth_models.dart.example lib/torn-pda-native/auth/native_auth_models.dart

  [ -f lib/config/native_auth_provider.dart.example ] && \
    [ ! -f lib/torn-pda-native/auth/native_auth_provider.dart ] && \
    cp lib/config/native_auth_provider.dart.example lib/torn-pda-native/auth/native_auth_provider.dart

  [ -f lib/config/native_user_provider.dart.example ] && \
    [ ! -f lib/torn-pda-native/auth/native_user_provider.dart ] && \
    cp lib/config/native_user_provider.dart.example lib/torn-pda-native/auth/native_user_provider.dart

  [ -f lib/config/native_login_widget.dart.example ] && \
    [ ! -f lib/torn-pda-native/auth/native_login_widget.dart ] && \
    cp lib/config/native_login_widget.dart.example lib/torn-pda-native/auth/native_login_widget.dart

  [ -f lib/config/stats_controller.dart.example ] && \
    [ ! -f lib/torn-pda-native/stats/stats_controller.dart ] && \
    cp lib/config/stats_controller.dart.example lib/torn-pda-native/stats/stats_controller.dart
fi

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
