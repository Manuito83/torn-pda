# Docker Development Environment

Run Flutter tests, analysis and builds without installing anything
except Docker.

> **Prefer a local Flutter install?** See [Building from Source](../docs/README.md#building-from-source) in the main docs.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) (20.10+)
- [Docker Compose](https://docs.docker.com/compose/install/) (V2, usually
  bundled with Docker Desktop)

That's it. No Flutter SDK, no Android SDK, no Java — the container has
everything.

## Quick start

```bash
# 1. Build the image (first time takes ~5 min, cached after that)
docker compose build

# 2. Run tests
docker compose run --rm app flutter test

# 3. Run analyzer
docker compose run --rm app flutter analyze --no-fatal-infos

# 4. Build debug APK
docker compose run --rm app flutter build apk --debug
```

Or use the Makefile shortcuts:

```bash
make docker-build    # step 1
make docker-test     # step 2
make docker-analyze  # step 3
make docker-apk      # step 4
make docker-all      # analyze + test + build
make docker-shell    # interactive bash inside the container
```

## How it works

```
┌──────────────────────────────────────────┐
│  Docker container (Ubuntu 22.04)         │
│                                          │
│  Flutter 3.41.6  (Dart 3.11.4)           │
│  Java 21 (OpenJDK)                       │
│  Android SDK 34                          │
│                                          │
│  /app  ← your project mounted here       │
│                                          │
│  entrypoint.sh:                          │
│    1. copies config stubs if missing     │
│    2. runs flutter pub get if needed     │
│    3. executes your command              │
└──────────────────────────────────────────┘
```

- The project directory is **mounted** into the container (`-v .:/app`),
  so any changes you make on the host are immediately reflected inside.
- The host's CA certificate bundle (`/etc/ssl/certs`) is mounted
  read-only into the container so HTTPS connections trust the same
  certificates as your machine (handy behind corporate proxies).
- `GIT_SSL_NO_VERIFY=true` is set inside the image for git operations
  during the Docker build stage, where host certs aren't available yet.
- Gradle and pub caches are stored in Docker **named volumes** so they
  persist between runs — you won't re-download dependencies every time.
- The entrypoint script handles config stubs automatically, so you don't
  need to copy them manually.

## What you can run

| Command | What it does | Time |
|---------|-------------|------|
| `flutter test` | Unit tests | ~30s |
| `flutter test --coverage` | Tests + lcov report | ~30s |
| `flutter analyze` | Static analysis | ~60s |
| `flutter build apk --debug` | Debug APK build | ~3 min |
| `bash` | Interactive shell | instant |

## Caching

Two named volumes keep caches warm:

| Volume | What's cached | Saves |
|--------|--------------|-------|
| `gradle-cache` | Android build artifacts, Gradle plugins | ~2 min per build |
| `pub-cache` | Dart/Flutter packages | ~30s per pub get |

To nuke the caches:

```bash
docker compose down -v
```

## Config stubs

The entrypoint copies `.dart.example` files to their expected locations on
every run (if they don't already exist). This mirrors what the CI workflow
does, so test results should match between Docker and GitHub Actions.

Stubs handled automatically:

| Stub file | Copied to |
|-----------|-----------|
| `lib/config/*.dart.example` | `lib/config/*.dart` |
| `lib/config/firebase_options.dart.example` | `lib/firebase_options.dart` |
| `lib/config/native_auth_models.dart.example` | `lib/torn-pda-native/auth/native_auth_models.dart` |
| `lib/config/native_auth_provider.dart.example` | `lib/torn-pda-native/auth/native_auth_provider.dart` |
| `lib/config/native_user_provider.dart.example` | `lib/torn-pda-native/auth/native_user_provider.dart` |
| `lib/config/native_login_widget.dart.example` | `lib/torn-pda-native/auth/native_login_widget.dart` |
| `lib/config/stats_controller.dart.example` | `lib/torn-pda-native/stats/stats_controller.dart` |
| `android/app/google-services.json.example` | `android/app/google-services.json` |

Features that need real credentials (YATA proxy, native auth, TAC) won't
work, but analysis, tests and debug builds all succeed with these stubs.

## TLS / Corporate proxy

The image handles TLS-intercepting proxies in two ways:

1. **Build time**: `GIT_SSL_NO_VERIFY=true` is set in the Dockerfile so
   `git` and `curl -k` work during `docker compose build` even when no
   host certs are available.
2. **Run time**: `docker-compose.yml` mounts `/etc/ssl/certs` read-only
   from the host, so `dart pub get` and HTTPS connections inside the
   container trust the same CAs as your machine.

If you're behind a proxy that rewrites TLS certificates, this should work
out of the box. If you still see certificate errors at run time, check
that your host's CA bundle is up to date in `/etc/ssl/certs`.

## Troubleshooting

### "Permission denied" on Linux

Docker on Linux runs as root inside the container, which can create files
owned by root on the host. Options:

1. Add `user: "$(id -u):$(id -g)"` to the compose service
2. Or run `sudo chown -R $(whoami) .` after a Docker run

### "No space left on device"

The Android SDK + Flutter SDK + Gradle cache can eat disk. Clean up with:

```bash
docker system prune -a
docker volume prune
```

### Build takes forever the first time

The initial `docker compose build` downloads ~2 GB (Ubuntu + Flutter +
Android SDK). Subsequent builds use Docker layer caching and should be
near-instant unless you change the Dockerfile.

### Tests pass in Docker but fail locally (or vice versa)

The Docker image pins a specific Flutter version (`FLUTTER_VERSION` in the
Dockerfile). Make sure your local Flutter matches. Check with
`flutter --version`.

### Certificate errors inside the container

If `flutter pub get` or other HTTPS calls fail with certificate errors:

1. Make sure `/etc/ssl/certs` exists on your host and contains your CA
   certificates (most Linux distros populate this automatically).
2. On macOS / Docker Desktop, the host cert mount may not work — you can
   add `SSL_CERT_FILE` or `CURL_CA_BUNDLE` env vars pointing to your
   cert bundle inside the compose file.
