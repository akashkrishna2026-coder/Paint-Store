# 🧪 Integration Testing Guide

Complete guide for running Flutter integration tests with comprehensive report generation.

## Quick Start

### 1. **Basic Test Execution**
```bash
# Simple run (no reports)
flutter test integration_test/

# With expanded output
flutter test integration_test/ -r expanded
```

### 2. **Using Built-in Report Script**
```bash
cd /home/akash/Documents/Paint-Store-backup

# Run tests with basic reports
./integration_test/run_integration_tests.sh
```

**Generates:**
- `integration_test/report.txt` - Human-readable
- `integration_test/report.json` - JSON format
- `integration_test/junit.xml` - JUnit XML (if tojunit installed)

### 3. **Advanced Report Generation** ⭐
```bash
# Run tests with timestamped reports + HTML viewer
./integration_test/run_tests_with_reports.sh
```

**Generates:**
- All basic reports
- HTML dashboard with test summary
- Timestamped report folder
- Symlink to latest report

**View HTML Report:**
```bash
xdg-open integration_test/latest/report.html
```

---

## Report Formats Explained

### 📄 JSON Report (`report.json`)
```json
{
  "testID": 1,
  "result": "success",
  "suite": {...},
  "groups": [...]
}
```
**Use for:** CI/CD pipelines, automated parsing

### 📝 Text Report (`report.txt`)
```
00:00 +0: loading tests...
02:13 +2 ~2: All tests passed!
```
**Use for:** Quick human review, logs

### 🏗️ JUnit XML (`junit.xml`)
```xml
<testsuites>
  <testsuite name="integration_test" tests="4" failures="0">
    <testcase name="Login test" time="15.2"/>
  </testsuite>
</testsuites>
```
**Use for:** Jenkins, GitLab CI, GitHub Actions

### 🌐 HTML Dashboard (`report.html`)
Interactive web page with:
- Test count summary (passed/failed/skipped)
- Full test output
- Links to all reports
- Timestamps

---

## Advanced Usage

### Running Specific Tests

```bash
# Single test file
flutter test integration_test/app_test.dart

# With pattern matching
flutter test integration_test/ --plain-name "Login"

# Specific test by name
flutter test integration_test/app_test.dart \
  --plain-name "Login with valid email and password"
```

### With Authentication Credentials

```bash
flutter test integration_test/ \
  --dart-define=TEST_EMAIL=test@example.com \
  --dart-define=TEST_PASSWORD=testpass123 \
  -r expanded | tee integration_test/report.txt
```

### Continuous Testing (Watch Mode)

```bash
# Install watch tool
dart pub global activate test_watcher

# Run in watch mode
flutter test integration_test/ --watch
```

### Running on Different Devices

```bash
# List available devices
flutter devices

# Run on specific device
flutter test integration_test/ -d chrome

# Run on Android emulator
flutter test integration_test/ -d emulator-5554

# Run on physical device
flutter test integration_test/ -d <device-id>
```

---

## CI/CD Integration

### GitHub Actions

```yaml
name: Integration Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run integration tests
        run: |
          flutter test integration_test/ -r json > report.json
          flutter test integration_test/ -r expanded > report.txt
        env:
          TEST_EMAIL: ${{ secrets.TEST_EMAIL }}
          TEST_PASSWORD: ${{ secrets.TEST_PASSWORD }}
      
      - name: Upload test reports
        uses: actions/upload-artifact@v3
        if: always()
        with:
          name: test-reports
          path: |
            report.json
            report.txt
```

### GitLab CI

```yaml
integration_tests:
  stage: test
  image: cirrusci/flutter:stable
  script:
    - flutter pub get
    - flutter test integration_test/ -r json > report.json
    - flutter test integration_test/ -r expanded | tee report.txt
  artifacts:
    when: always
    paths:
      - report.json
      - report.txt
    reports:
      junit: junit.xml
```

---

## Troubleshooting

### Tests Hanging?
```bash
# Use timeout command
timeout 300s flutter test integration_test/
```

### Firebase Connection Issues?
```bash
# Check Firebase config
flutter clean
flutter pub get
```

### Memory Issues?
```bash
# Run tests one by one
for file in integration_test/*.dart; do
    echo "Testing $file"
    flutter test "$file"
done
```

### View Detailed Logs
```bash
# Enable verbose logging
flutter test integration_test/ -v
```

---

## Installing Report Tools

### JUnit Reporter
```bash
dart pub global activate junitreport
export PATH="$PATH":"$HOME/.pub-cache/bin"

# Verify installation
which tojunit
```

### Coverage Tool (Optional)
```bash
dart pub global activate coverage

# Run tests with coverage
flutter test integration_test/ --coverage
genhtml coverage/lcov.info -o coverage/html
xdg-open coverage/html/index.html
```

---

## Report Storage Best Practices

### Organize by Date
```bash
mkdir -p test-reports/$(date +%Y-%m-%d)
flutter test integration_test/ -r json > test-reports/$(date +%Y-%m-%d)/report.json
```

### Archive Old Reports
```bash
# Compress reports older than 7 days
find integration_test/reports -type d -mtime +7 -exec tar -czf {}.tar.gz {} \; -exec rm -rf {} \;
```

---

## Quick Reference

| Command | Output |
|---------|--------|
| `flutter test integration_test/` | Console only |
| `flutter test integration_test/ -r json` | JSON format |
| `flutter test integration_test/ -r expanded` | Detailed text |
| `flutter test integration_test/ -r compact` | Brief summary |
| `./run_integration_tests.sh` | Multiple formats |
| `./run_tests_with_reports.sh` | All formats + HTML |

---

## Need Help?

- Check `integration_test/README.md` for test structure
- View test examples in `integration_test/app_test.dart`
- Flutter testing docs: https://docs.flutter.dev/testing/integration-tests
