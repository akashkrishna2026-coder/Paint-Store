#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(dirname "$0")/.."
OUT_DIR="$(dirname "$0")"

# Set Java 17 for Gradle (required by Android Gradle plugin)
export JAVA_HOME=/usr/lib/jvm/java-1.17.0-openjdk-amd64

# Set timeout to prevent tests from hanging indefinitely (5 minutes)
export TIMEOUT_DURATION=300

echo "Starting integration tests with ${TIMEOUT_DURATION}s timeout..."

# Build optional --dart-define flags for env-driven auth test
DEFINE_ARGS=""
if [ -n "${TEST_EMAIL:-}" ]; then
  DEFINE_ARGS+=" --dart-define=TEST_EMAIL=${TEST_EMAIL}"
fi
if [ -n "${TEST_PASSWORD:-}" ]; then
  DEFINE_ARGS+=" --dart-define=TEST_PASSWORD=${TEST_PASSWORD}"
fi

if [ -z "$DEFINE_ARGS" ]; then
  echo "[info] TEST_EMAIL/TEST_PASSWORD not set; env-driven auth test will be skipped."
else
  echo "[info] Using dart-defines for env-driven auth test: ${DEFINE_ARGS}"
fi

# Run tests once with expanded output (both human-readable and for parsing)
# Using 'timeout' command to prevent indefinite hangs
if command -v timeout >/dev/null 2>&1; then
  timeout ${TIMEOUT_DURATION}s flutter test ${DEFINE_ARGS} integration_test -r expanded | tee "$OUT_DIR/report.txt" || {
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 124 ]; then
      echo "[ERROR] Tests timed out after ${TIMEOUT_DURATION} seconds" | tee -a "$OUT_DIR/report.txt"
    fi
  }
else
  # Fallback if timeout command is not available
  flutter test ${DEFINE_ARGS} integration_test -r expanded | tee "$OUT_DIR/report.txt" || true
fi

# Generate JSON report from the text output using dart test json reporter
# This is more efficient than running tests twice
if command -v flutter >/dev/null 2>&1; then
  timeout ${TIMEOUT_DURATION}s flutter test ${DEFINE_ARGS} integration_test -r json > "$OUT_DIR/report.json" 2>&1 || {
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 124 ]; then
      echo "{\"error\": \"Test execution timed out\"}" > "$OUT_DIR/report.json"
    fi
  }
fi

# 3) Try to produce JUnit XML if 'tojunit' is available
if command -v tojunit >/dev/null 2>&1; then
  cat "$OUT_DIR/report.txt" | tojunit > "$OUT_DIR/junit.xml" 2>/dev/null || true
else
  echo "[info] 'tojunit' not found. To install: 'dart pub global activate junitreport' and add it to PATH." >&2
fi

# 4) Generate compact Markdown summary from JSON
if command -v dart >/dev/null 2>&1 && [ -f "$OUT_DIR/report.json" ]; then
  dart "$(dirname "$0")/json_to_markdown.dart" "$OUT_DIR/report.json" "$OUT_DIR/report.md" 2>/dev/null || true
else
  echo "[info] Dart not available or JSON report missing; skipping Markdown summary generation." >&2
fi

echo ""
echo "Integration tests completed!"
echo "Reports written to:"
[ -f "$OUT_DIR/report.txt" ] && echo "  - $OUT_DIR/report.txt" || true
[ -f "$OUT_DIR/report.json" ] && echo "  - $OUT_DIR/report.json" || true
[ -f "$OUT_DIR/junit.xml" ] && echo "  - $OUT_DIR/junit.xml" || true
[ -f "$OUT_DIR/report.md" ] && echo "  - $OUT_DIR/report.md" || true
