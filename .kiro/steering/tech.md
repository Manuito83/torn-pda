# Technology Stack

## Architecture

Flutter application structured around domain-specific UI pages backed by Providers (ChangeNotifier) and long-lived GetX controllers. Core flows start in `main.dart`, which initializes Firebase, background services (Workmanager, HomeWidget, Live Activities), local storage, and dependency wiring before mounting a `MultiProvider`. Torn API access is centralized in `lib/providers/api`, which handles V1/V2 clients, throttling, and shared error handling. Native capabilities (notifications, background fetch, widgets, audio) are abstracted behind `utils/` helpers so UI code stays declarative.

## Core Technologies

- **Language**: Dart 3 (null-safe, per `environment.sdk >=3.0.0`)
- **Framework**: Flutter 3.3+ with Material 3 styling
- **Runtime**: Android, iOS, Windows builds plus Firebase Functions backend

## Key Libraries

- **State & orchestration**: `provider`, `get`, `rxdart`, `workmanager`
- **Networking & API clients**: `dio`, `chopper`, `swagger_dart_code_generator`, `http`
- **Realtime & messaging**: `firebase_*` suite, `sendbird_chat_sdk`, `bot_toast`
- **Persistence**: `sembast` (primary store), `shared_preferences`, encrypted prefs, `Prefs` migration helpers
- **UI & UX**: `flutter_inappwebview`, `fl_chart`, `bot_toast`, `toastification`, `home_widget`
- **Security & config**: `envied`, `encrypt_shared_preferences`
- **Automation assets**: bundled `userscripts/` JS files executed via WebView bridge

## Development Standards

### Type Safety
`analysis_options.yaml` extends `package:lints/recommended` with selective overrides (e.g., allow constant identifier names). All code is null-safe and compiled with Dart 3—prefer explicit types and avoid `dynamic` outside integration boundaries.

### Code Quality
- Enforce ordered imports via `import_sorter`.
- Use `build_runner` to regenerate Swagger/JSON code (`json_serializable`, `swagger_dart_code_generator`, `envied_generator`).
- Keep shared logic in `utils/` or `providers/` so UI pages remain declarative widgets.

### Testing
No formal `test/` suite today; manual QA and community beta testing catch regressions. When adding critical logic (e.g., API scheduling, calculators), add focused Dart unit tests or widget tests alongside the new module to start building coverage.

## Development Environment

### Required Tools
- Flutter SDK 3.3+ (recommended latest stable)
- Dart SDK 3.x (ships with Flutter)
- Platform toolchains (Xcode for iOS, Android Studio/SDK, Windows Desktop SDK if applicable)
- Firebase CLI + `melos`/`flutterfire` tooling when touching backend configs

### Common Commands
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run --profile   # local device testing
flutter build apk --release  # store / QA builds
flutter test            # add when new tests are introduced
```

## Key Technical Decisions

- **Hybrid state management**: Providers drive widget rebuilds, while GetX controllers (`ApiCallerController`, `TargetsProvider`, etc.) handle background timers, queues, and cross-feature state that needs lifecycle hooks.
- **Rate-limited API orchestration**: All Torn API calls flow through a centralized queue that enforces per-minute limits, retries, and diagnostics to protect player API keys.
- **Firebase-first mobile services**: Analytics, Crashlytics, Remote Config, Messaging, Functions, and Realtime DB are all initialized at startup so server-side toggles and push workflows stay in sync.
- **Local-first persistence**: Settings and cached payloads migrate from SharedPreferences into Sembast for structured storage, ensuring widgets, Workmanager, and Sendbird controllers can operate offline.
- **Background + surface extensions**: Workmanager tasks, Live Activities, Home Widgets, and native notifications share helpers in `utils/` so travel alarms, chain alerts, and stock monitors run even when the UI is closed.
- **WebView + JS bridge**: `flutter_inappwebview` hosts Torn pages and executes bundled or user-supplied scripts through vetted handlers, enabling extensibility without modifying native code.

---
_Document standards and patterns, not every dependency_
