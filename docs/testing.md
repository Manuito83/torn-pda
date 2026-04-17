# Testing Guide

How to set up and run tests for Torn PDA — locally, in CI, or inside Docker.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Running tests locally](#running-tests-locally)
- [What's tested](#whats-tested)
- [Writing new tests](#writing-new-tests)
- [Test environment setup](#test-environment-setup)
- [CI pipeline](#ci-pipeline)
- [Docker testing](#docker-testing)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

| Tool | Minimum version | Check with |
|------|----------------|------------|
| Flutter SDK | 3.3.0+ | `flutter --version` |
| Dart SDK | 3.0.0+ | `dart --version` |

No device, emulator, or simulator needed — all current tests are pure Dart
unit tests that run headless.

---

## Running tests locally

### 1. Copy config stubs (first time only)

The project keeps private config files (API keys etc.) out of version
control. You need the stubs so that imports resolve:

```bash
cd lib/config
for f in *.dart.example; do cp "$f" "${f%.example}"; done

cd ../torn-pda-native
mkdir -p auth stats
cp ../config/native_auth_models.dart.example    auth/native_auth_models.dart
cp ../config/native_auth_provider.dart.example   auth/native_auth_provider.dart
cp ../config/native_user_provider.dart.example   auth/native_user_provider.dart
cp ../config/native_login_widget.dart.example    auth/native_login_widget.dart
cp ../config/stats_controller.dart.example       stats/stats_controller.dart
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run all tests

```bash
flutter test
```

### 4. Run with coverage

```bash
flutter test --coverage
# Coverage report lands in coverage/lcov.info
```

### 5. Run a single file

```bash
flutter test test/models/userscript_model_test.dart
```

### 6. Run tests matching a keyword

```bash
flutter test --name "shouldInject"
```

---

## What's tested

### Models (`test/models/`)

| File | What it covers |
|------|---------------|
| `userscript_model_test.dart` | `parseHeader` — extracts metadata from userscript headers |
| | `isNewerVersion` — semantic version comparison |
| | `shouldInject` — Tampermonkey-style @match pattern matching |
| | `tryGetMatches`, `tryGetUrl`, `tryGetVersion` — safe header extraction |
| | `toJson` / `fromJson` round-trip serialization |

### Utilities (`test/utils/`)

| File | What it covers |
|------|---------------|
| `number_formatter_test.dart` | `formatBigNumbers` — K / M / B shorthand for large numbers |
| `profit_formatter_test.dart` | `formatProfit` — travel profit display formatting |
| `country_check_test.dart` | `countryCheck` — player location from status + description |
| | `isTraveling` — active flight detection |
| `travel_times_test.dart` | `TravelTimes.getCountry` — name → enum mapping |
| | `travelTimeMinutesOneWay` — travel duration by destination × ticket |
| `html_parser_test.dart` | `HtmlParser.fix` — strip HTML tags to plain text |
| `events_timeline_fixes_test.dart` | `fixHrefAttributes` — deduplicate malformed torn.com hrefs |
| | `processEventMessage` — normalise event message text |
| | `stripUnsupportedHtmlTags` — allow only `<a>` and `<b>` tags |

---

## Writing new tests

### Where to put them

Mirror the source path under `test/`:

```
lib/utils/some_helper.dart    →    test/utils/some_helper_test.dart
lib/models/my_model.dart      →    test/models/my_model_test.dart
```

### Template

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/utils/some_helper.dart';

void main() {
  group('someFunction', () {
    test('does X when given Y', () {
      expect(someFunction('input'), 'expected output');
    });

    test('handles edge case', () {
      expect(someFunction(null), isNull);
    });
  });
}
```

### What makes a good test target

Best candidates are **pure functions** — no `BuildContext`, no network, no
Firebase. Look for:

- `static` methods on model classes
- Top-level utility functions
- Anything in `lib/utils/` that takes inputs and returns outputs
- `fromJson` / `toJson` round-trips

### Functions ready for future tests

These have been identified as testable but don't have tests yet:

| File | Function | What it does |
|------|----------|--------------|
| `lib/utils/time_formatter.dart` | `TimeFormatter` class | Date/time formatting (needs timezone mocking) |
| `lib/utils/timestamp_ago.dart` | `readTimestamp` | Relative time display |
| `lib/utils/memory_info.dart` | `MemoryInfo.formatBytes` | Byte → MB formatting |
| `lib/utils/stats_calculator.dart` | `StatsCalculator.calculateStats` | Player stats estimation |
| `lib/utils/travel/travel_times.dart` | All countries × tickets | Full combinatorial coverage |
| `lib/utils/shared_prefs_backup.dart` | `inspectBackup`, `decodeBackup` | Backup encode/decode |
| `lib/models/chaining/ffscouter/` | `FFScouterCacheEntry` | Cache freshness, JSON round-trip |

---

## Test environment setup

### Config stubs

The CI and local test setup both need config stubs. A one-liner to set
everything up:

```bash
# From the project root
cd lib/config && for f in *.dart.example; do cp "$f" "${f%.example}"; done && cd ../torn-pda-native && mkdir -p auth stats && cp ../config/native_auth_models.dart.example auth/native_auth_models.dart && cp ../config/native_auth_provider.dart.example auth/native_auth_provider.dart && cp ../config/native_user_provider.dart.example auth/native_user_provider.dart && cp ../config/native_login_widget.dart.example auth/native_login_widget.dart && cp ../config/stats_controller.dart.example stats/stats_controller.dart && cd ../..
```

### No emulator needed

All current tests are pure Dart — they run in the Dart VM, not on a device.
This means they work on any OS (Linux, macOS, Windows) without Android SDK
or Xcode.

### IDE integration

- **VS Code**: Install the Flutter extension. Tests show green/red indicators
  in the gutter. `Ctrl+Shift+P` → "Flutter: Run All Tests".
- **Android Studio / IntelliJ**: Right-click the `test/` folder → "Run Tests".

---

## CI pipeline

Tests run automatically on every push and PR against `master`.

| Job | Command | What it checks |
|-----|---------|---------------|
| **Analyze** | `flutter analyze` | Type errors, lint violations, unused imports |
| **Test** | `flutter test --coverage` | All unit tests pass |
| **Build** | `flutter build apk --debug` | Project still compiles |

No configuration needed — GitHub Actions is free for public repos.

See `.github/workflows/README.md` for maintenance notes.

---

## Docker testing

If you don't want to install Flutter locally, you can run everything inside
a container. See the Docker setup in the project root:

```bash
# Build the image
docker compose build

# Run tests
docker compose run --rm app flutter test

# Run analyzer
docker compose run --rm app flutter analyze

# Interactive shell
docker compose run --rm app bash
```

The Docker image comes with the Flutter SDK pre-installed and the config
stubs already copied, so there's zero setup once the image is built.

See `docker/README.md` for more details.

---

## Troubleshooting

### "Could not find package torn_pda"

Run `flutter pub get` first.

### "Cannot find dart:ui" or widget-related errors

Make sure you're importing `package:flutter_test/flutter_test.dart`, not
`package:test/test.dart`. The Flutter test runner initialises the binding
that provides `dart:ui`.

### Tests pass locally but fail in CI

Check that the config stubs are being copied. The CI workflow handles this
automatically, but if you've added a new config file you may need to update
the copy step in `.github/workflows/ci.yml`.

### Coverage report is empty

Make sure at least one test file exists and runs successfully. Then check
`coverage/lcov.info` — it's generated by `flutter test --coverage`.

### Import errors for platform-specific code

Some source files import `dart:io` or platform plugins that don't exist in
the test environment. If you're testing a function from such a file, extract
the pure logic into a separate file that doesn't depend on platform imports,
then test that file instead.
