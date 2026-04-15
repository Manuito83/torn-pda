# ──────────────────────────────────────────────────────────────
# Makefile — common dev commands for Torn PDA
#
# Shortcuts for the most frequent tasks. Works locally (if you
# have Flutter installed) and inside Docker (prefix with
# `docker compose run --rm app`).
#
# Usage:
#   make test         # run unit tests
#   make analyze      # static analysis
#   make build        # debug APK
#   make coverage     # tests + coverage report
#   make all          # analyze + test + build
#
#   make docker-build # build the Docker image
#   make docker-test  # run tests inside Docker
#   make docker-shell # interactive shell in the container
#
# See docs/testing.md for the full testing guide.
# ──────────────────────────────────────────────────────────────

.PHONY: all test analyze build coverage clean \
        docker-build docker-test docker-analyze docker-shell \
        setup

# ── Local commands ───────────────────────────────────────────

## Run all checks (analyze → test → build)
all: analyze test build

## Run unit tests
test:
	flutter test

## Run static analysis
analyze:
	flutter analyze --no-fatal-infos

## Build debug APK
build:
	flutter build apk --debug

## Run tests with coverage
coverage:
	flutter test --coverage
	@echo "Coverage report: coverage/lcov.info"

## Install dependencies
setup:
	flutter pub get

## Remove build artifacts
clean:
	flutter clean
	rm -rf coverage/

# ── Docker commands ──────────────────────────────────────────

## Build the dev Docker image
docker-build:
	docker compose build

## Run tests inside Docker
docker-test:
	docker compose run --rm app flutter test

## Run analyzer inside Docker
docker-analyze:
	docker compose run --rm app flutter analyze --no-fatal-infos

## Build APK inside Docker
docker-apk:
	docker compose run --rm app flutter build apk --debug

## Run tests with coverage inside Docker
docker-coverage:
	docker compose run --rm app flutter test --coverage

## Open an interactive shell in the container
docker-shell:
	docker compose run --rm app bash

## Run all checks inside Docker
docker-all: docker-analyze docker-test docker-apk
