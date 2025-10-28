# Integration Testing Guide

This project already includes integration tests under `integration_test/`.
This guide shows how to run them locally and produce useful test reports to share.

## Prerequisites
- Flutter SDK installed and set up.
- **Java 17 or higher** (required for Android Gradle plugin). The test script automatically uses Java 17 if available at `/usr/lib/jvm/java-1.17.0-openjdk-amd64`.
- An emulator or a physical device connected for full app tests if needed.
- For auth-flow tests that depend on Firebase auth, create a dedicated test account.

## Test Types Included
- App smoke/UI tests (widget-level and integration style)
- Optional auth flow tests that require credentials (see below)

## Running Tests
- Run all tests (console):
  ```bash
  flutter test integration_test
  ```
- Run on a specific device (for device-driven tests):
  ```bash
  flutter test integration_test --device-id <DEVICE_ID>
  ```

## Reports (JSON, JUnit, Markdown)
Use the helper script below to generate multiple report formats.

1) JSON + expanded text + JUnit XML + Markdown summary:
   ```bash
   bash integration_test/run_integration_tests.sh
   ```
   Outputs:
   - `integration_test/report.json`
   - `integration_test/report.txt`
   - `integration_test/junit.xml` (via tojunit)
   - `integration_test/report.md` (compact summary)

Notes:
- The script will attempt to use `tojunit` (from the `junitreport` Dart package). If its not available, it will suggest how to install it without modifying your system automatically.

## Optional: Credentialled Auth Tests
Some auth tests need credentials. You can supply them via `--dart-define`.
- Example:
  ```bash
  flutter test integration_test/app_auth_env_test.dart \
    --dart-define=TEST_EMAIL=testuser@example.com \
    --dart-define=TEST_PASSWORD=YourValidTestPassword1!
  ```
- If the variables are not provided, the test file marks the auth tests as skipped.

## Troubleshooting
- If tests involving network/Firebase feel flaky, increase pumpAndSettle durations locally.
- Ensure your emulator/device has network access and Google services if required.
- For `tojunit` conversion, install once:
  ```bash
  dart pub global activate junitreport
  export PATH="$PATH:$HOME/.pub-cache/bin"
  ```

## CI (Optional)
You can run the same script in CI and collect `junit.xml` as an artifact to visualize results in most CI systems.
