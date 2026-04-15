# CI Workflow — Maintenance Notes

## What runs

| Job | What it does | Approx time |
|-----|-------------|-------------|
| **analyze** | `flutter analyze` — static analysis, catches type errors and lint violations | ~2 min |
| **test** | `flutter test --coverage` — runs everything under `test/` | ~2 min |
| **build** | `flutter build apk --debug` — proves the project still compiles | ~5 min |

All three jobs run **in parallel** on every push to `develop` or `master`
and every PR targeting either branch.

## Costs

GitHub Actions is **free for public repos** (unlimited minutes). If the repo
ever goes private, the free tier still gives 2,000 min/month which is plenty.

## Config stubs

The project keeps private config files out of version control (API keys, etc.).
The CI copies the `.dart.example` stubs before running anything so that all
imports resolve. This means CI builds with **placeholder values** — features
that need real credentials (YATA proxy, native auth, TAC) won't work, but
analysis and tests still pass.

## Updating the Flutter version

Change `FLUTTER_VERSION` in the `env:` block at the top of `ci.yml`. The
`subosito/flutter-action` handles downloading and caching the SDK.

## Adding more jobs

Common additions:
- **Windows build**: add another job with `runs-on: windows-latest` and
  `flutter build windows`
- **iOS build**: needs `runs-on: macos-latest` + Xcode (free but slower)
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
