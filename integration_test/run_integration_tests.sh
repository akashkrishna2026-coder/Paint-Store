#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(dirname "$0")/.."
OUT_DIR="$(dirname "$0")"

# Set Java 17 for Gradle (required by Android Gradle plugin)
export JAVA_HOME=/usr/lib/jvm/java-1.17.0-openjdk-amd64

# 1) JSON report
flutter test integration_test -r json > "$OUT_DIR/report.json" || true

# 2) Expanded text report (human readable)
flutter test integration_test -r expanded | tee "$OUT_DIR/report.txt" || true

# 3) Try to produce JUnit XML if 'tojunit' is available
if command -v tojunit >/dev/null 2>&1; then
  cat "$OUT_DIR/report.txt" | tojunit > "$OUT_DIR/junit.xml" || true
else
  echo "[info] 'tojunit' not found. To install: 'dart pub global activate junitreport' and add it to PATH." >&2
fi

# 4) Generate compact Markdown summary from JSON
if command -v dart >/dev/null 2>&1; then
  dart "$(dirname "$0")/json_to_markdown.dart" "$OUT_DIR/report.json" "$OUT_DIR/report.md" || true
else
  echo "[info] Dart not available on PATH; skipping Markdown summary generation." >&2
fi

echo "Reports written to:"
echo "  - $OUT_DIR/report.json"
echo "  - $OUT_DIR/report.txt"
[ -f "$OUT_DIR/junit.xml" ] && echo "  - $OUT_DIR/junit.xml" || true
[ -f "$OUT_DIR/report.md" ] && echo "  - $OUT_DIR/report.md" || true
