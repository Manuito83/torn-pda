# Contributing to Torn PDA

Thanks for your interest in contributing! Here's how to get started.

## Getting help

Join us on [Discord](https://discord.gg/vyP23kJ), it's the fastest way to get answers.

## Setting up the project

Follow the **Building from Source** guide in [docs/README.md](docs/README.md). The short version:

1. Clone the repo and switch to the `develop` branch
2. Copy config stubs: `cd lib/config && for f in *.dart.example; do cp "$f" "${f%.example}"; done`
3. Set up native stubs (see [docs/README.md](docs/README.md) for details)
4. `flutter pub get`

Alternatively, use **Docker** to skip the Flutter/Java/Android SDK install entirely: see [docker/README.md](docker/README.md).

## Running tests

```bash
flutter test
```

All current tests are pure Dart, no device or emulator needed. See [docs/testing.md](docs/testing.md) for the full guide (writing new tests, coverage, troubleshooting).

## CI

Every push and PR to `develop` or `master` runs three checks automatically via GitHub Actions:

- **Analyze**: static analysis
- **Test**: unit tests with coverage
- **Build**: debug APK compilation

You don't need to configure anything. See [.github/workflows/README.md](.github/workflows/README.md) for maintenance notes.

## Submitting a PR

1. Fork the repo and create your branch from `develop`
2. Make your changes
3. Run `flutter test` and `flutter analyze` locally
4. Open a PR against `develop`
5. Describe what you changed and why

## Project structure

See [docs/architecture.md](docs/architecture.md) for a high-level overview of the codebase with diagrams.

## Branch workflow

- `develop`: active development branch (PRs go here)
- `master`: stable releases
