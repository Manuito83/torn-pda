# Build Android APK Plan

The project is a Flutter application. The `android/app/build.gradle` file is already configured to read signing information from a `key.properties` file located in the `android/` directory.

## Prerequisities

- User must have the keystore file path, alias, and passwords.

## Setup Steps

1. **Create `key.properties`**:
    - Location: `android/key.properties`
    - Content:

      ```properties
      storePassword=<your-store-password>
      keyPassword=<your-key-password>
      keyAlias=<your-key-alias>
      storeFile=<path-to-your-keystore-file>
      ```

    - Note: `storeFile` should be an absolute path (e.g., `C:/Path/To/keystore.jks`) or a path relative to `android/app/`.

2. **Build Command**:
    - Run the following command in the terminal:

      ```bash
      flutter build apk --release
      ```

## Verification

- The APK will be generated at `build/app/outputs/flutter-apk/app-release.apk`.
