# Test Suite

Unit and widget tests for the Torn PDA Flutter application.

## Quick start

```bash
# Run all tests
flutter test

# Run all tests with coverage
flutter test --coverage

# Run a single test file
flutter test test/models/userscript_model_test.dart

# Run tests matching a name
flutter test --name "shouldInject"
```

## Directory layout

```
test/
├── models/                          # Data-model tests (parsing, serialization, logic)
│   └── userscript_model_test.dart   # @match patterns, header parsing, version comparison
├── utils/                           # Utility function tests
│   ├── country_check_test.dart      # Player location detection
│   ├── events_timeline_fixes_test.dart  # HTML cleanup for event messages
│   ├── html_parser_test.dart        # Generic HTML → plain text
│   ├── number_formatter_test.dart   # K / M / B shorthand
│   ├── profit_formatter_test.dart   # Travel profit display
│   └── travel_times_test.dart       # Country lookup & travel durations
└── README.md                        # This file
```

## Writing new tests

1. Mirror the `lib/` path under `test/`.  
   e.g. `lib/utils/foo.dart` → `test/utils/foo_test.dart`

2. Import `package:flutter_test/flutter_test.dart` (not `package:test`).

3. Group related assertions with `group()` and use descriptive test names.

4. Prefer testing public API — avoid reaching into private methods.  
   If a private helper is complex enough to need its own tests, consider
   making it a package-private (non-underscore) function.

5. Keep tests **deterministic** — no real network calls, no filesystem
   writes, no timers. Use fakes/stubs where necessary.

## What to test

Focus on **pure logic** first — functions that take inputs and return
outputs without side effects:

- Model parsing (`fromJson`, `parseHeader`, version comparison)
- Formatters (numbers, dates, profit)
- String manipulation (HTML fixes, country detection)
- URL matching patterns
- Travel time calculations

Widget tests and integration tests can be added later as the suite
matures.

## CI

Tests run automatically on every PR via GitHub Actions.  
See `.github/workflows/README.md` for details.
