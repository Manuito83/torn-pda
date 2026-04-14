# ──────────────────────────────────────────────────────────────
# Torn PDA — Development Docker Image
#
# Provides a ready-to-go Flutter environment for running tests,
# analysis and debug builds WITHOUT installing Flutter locally.
#
# Usage:
#   docker compose build
#   docker compose run --rm app flutter test
#
# See docker/README.md for full docs.
# ──────────────────────────────────────────────────────────────

FROM ubuntu:22.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# ── System packages ──────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        git \
        unzip \
        xz-utils \
        zip \
        ca-certificates \
        libglu1-mesa \
        # Java 17 for Android SDK / Gradle
        openjdk-17-jdk-headless \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# ── Flutter SDK ──────────────────────────────────────────────
ENV FLUTTER_VERSION="3.41.6"
ENV FLUTTER_HOME="/opt/flutter"
ENV PATH="${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin:${PATH}"

RUN git clone --depth 1 --branch ${FLUTTER_VERSION} \
        https://github.com/flutter/flutter.git ${FLUTTER_HOME} \
    && flutter precache \
    && flutter config --no-analytics \
    && dart --disable-analytics

# ── Android SDK (command-line tools only — enough for builds) ─
ENV ANDROID_HOME="/opt/android-sdk"
ENV PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}"

RUN mkdir -p ${ANDROID_HOME}/cmdline-tools \
    && curl -fsSL "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" \
       -o /tmp/cmdline-tools.zip \
    && unzip -q /tmp/cmdline-tools.zip -d ${ANDROID_HOME}/cmdline-tools \
    && mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest \
    && rm /tmp/cmdline-tools.zip \
    && yes | sdkmanager --licenses > /dev/null 2>&1 \
    && sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# ── Working directory ────────────────────────────────────────
WORKDIR /app

# ── Copy config stubs so imports resolve ─────────────────────
# (done at build time so the image is self-contained)
COPY lib/config/ /tmp/config-stubs/

RUN mkdir -p /app/lib/config \
    && mkdir -p /app/lib/torn-pda-native/auth \
    && mkdir -p /app/lib/torn-pda-native/stats

# The actual stub copy happens in the entrypoint (after the
# project is mounted) — see docker/entrypoint.sh

# ── Entrypoint ───────────────────────────────────────────────
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
