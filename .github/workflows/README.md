# CI Workflow — Maintenance Notes

## What runs

| Job | What it does | Approx time |
|-----|-------------|-------------|
| **analyze** | `flutter analyze` — static analysis, catches type errors and lint violations | ~2 min |
| **test** | `flutter test --coverage` — runs everything under `test/` | ~2 min |
| **format** | `dart format --set-exit-if-changed lib test` — catches unformatted Dart code | <1 min |
| **generated** | `dart run build_runner build --delete-conflicting-outputs` then `git diff --exit-code` — catches stale generated Dart output | ~3-6 min |
| **functions** | `npm ci`, `npm run lint`, `npm run build` under `cloud_functions/functions` | ~2 min |
| **dependency-review** | `actions/dependency-review-action` — fails PRs that introduce high/critical vulnerable dependencies | <1 min |
| **build** | `flutter build apk --debug` — proves the project still compiles | ~5 min |
| **ios** | `flutter build ios --no-codesign` — proves the iOS project still compiles | ~10-15 min |

`analyze`, `test`, `format`, `generated`, and `functions` run **in parallel**
on every push to `develop` or `master` and every PR targeting either branch.
`dependency-review`, `build`, and `ios` only run on **pull requests**.

## Costs

GitHub Actions is **free for public repos** (unlimited minutes). If the repo
ever goes private, the free tier still gives 2,000 min/month which is plenty.

## Config stubs

The project keeps private config files out of version control (API keys, etc.).
The CI copies the `.dart.example` stubs before running anything so that all
imports resolve. This means CI builds with **placeholder values** — features
that need real credentials (YATA proxy, native auth, TAC) won't work, but
analysis and tests still pass.

The iOS build also creates temporary CI-only stubs for `ios/Flutter/Secrets.xcconfig`
and `ios/Runner/GoogleService-Info.plist`. Those files are intentionally not
committed because real local/release builds need private Google/Firebase values.

## Experimental checks

The `format`, `generated`, and `dependency-review` jobs were added as extra
verification signals. If they prove too noisy, tune them before making them
required branch-protection checks.

## Updating the Flutter version

Change `FLUTTER_VERSION` in the `env:` block at the top of `ci.yml`. The
`subosito/flutter-action` handles downloading and caching the SDK.

## Updating the Node version

The Cloud Functions job uses Node 22 to match `cloud_functions/functions/package.json`.
If the Firebase Functions runtime changes, update both places together.

## Adding more jobs

Common additions:
- **Windows build**: add another job with `runs-on: windows-latest` and
  `flutter build windows`
- **iOS build**: already runs on PRs using `macos-latest` + Xcode. Keep it PR-only unless
  we explicitly want slower direct-push checks too.
- **Code coverage thresholds**: parse `coverage/lcov.info` and fail if
  coverage drops below a target

## Concurrency

The workflow uses `concurrency` with `cancel-in-progress: true` — if you
push again to the same branch while a run is in progress, the old run gets
cancelled so you're not wasting minutes on stale code.

## First-time fork PRs

GitHub requires a maintainer to click **"Approve and run"** on the first
workflow run from a new contributor's fork. This is a security feature, not
a bug. After the first approval, subsequent runs from the same contributor
are automatic.
