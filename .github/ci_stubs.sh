#!/bin/bash
# Copies CI config stubs without overwriting

set -e
cd "$(dirname "$0")/.."

copy() {
  if [ ! -f "$2" ]; then
    mkdir -p "$(dirname "$2")"
    cp "$1" "$2"
  fi
}

for f in lib/config/*.dart.example; do
  copy "$f" "${f%.example}"
done
copy lib/config/firebase_options.dart.example lib/firebase_options.dart

for f in auth/native_auth_models auth/native_auth_provider auth/native_user_provider auth/native_login_widget \
         chat/chat_engine chat/chat_push chat/torn_chat_source \
         stats/stats_controller stats/usage_counters stats/app_settings_daily; do
  copy "lib/config/$(basename "$f").dart.example" "lib/torn-pda-native/$f.dart"
done

copy lib/utils/env/env.g.dart.example lib/utils/env/env.g.dart

if [ "$1" = "--android" ]; then
  copy android/app/google-services.json.example android/app/google-services.json
fi
