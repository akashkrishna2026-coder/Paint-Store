# Integration Tests

This directory contains integration tests for the Paint Store app.

## Running Tests

### Quick Start
```bash
cd /home/akash/Documents/Paint-Store-backup
./integration_test/run_integration_tests.sh
```

### Running Specific Test Files
```bash
# Run a specific test file
flutter test integration_test/app_test.dart

# Run with authentication tests (requires credentials)
flutter test integration_test/app_test.dart --dart-define=TEST_EMAIL=your-email@example.com --dart-define=TEST_PASSWORD=your-password
```

## Recent Fixes

### System Freezing Issues (Fixed)
The following improvements were made to prevent tests from hanging:

1. **Replaced unsafe `pumpAndSettle()` calls**
   - Added explicit timeouts (10 seconds max)
   - Replaced with `pump()` calls where appropriate
   - Prevents infinite loops from animations

2. **Added Firebase cleanup**
   - `tearDown()` now signs out users after each test
   - Prevents resource leaks and auth state conflicts

3. **Test script optimization**
   - Tests run once instead of twice
   - Added 5-minute timeout to prevent indefinite hangs
   - Better error handling and reporting

4. **Loading screen optimization**
   - Tests now skip 3-second loading delays
   - Prevents `CircularProgressIndicator` from blocking tests
   - Uses `test_helpers.dart` configuration

## Test Configuration

### Timeouts
- Test execution timeout: **5 minutes** (configurable in `run_integration_tests.sh`)
- Individual `pumpAndSettle` timeout: **10 seconds**
- Firebase operation timeout: **3 seconds**

### Test Credentials
For authentication tests, set these environment variables:
```bash
export TEST_EMAIL="test-user@example.com"
export TEST_PASSWORD="test-password"
```

Or pass them inline:
```bash
flutter test integration_test --dart-define=TEST_EMAIL=... --dart-define=TEST_PASSWORD=...
```

## Troubleshooting

### Tests Still Hanging?
1. Check if Firebase is accessible
2. Verify your network connection
3. Increase timeout in `run_integration_tests.sh`:
   ```bash
   export TIMEOUT_DURATION=600  # 10 minutes
   ```

### Memory Issues?
- Close other applications
- Run fewer tests at once
- Monitor system resources: `htop` or `top`

### Test Reports
After running tests, check these files:
- `integration_test/report.txt` - Human-readable output
- `integration_test/report.json` - JSON format for parsing
- `integration_test/report.md` - Markdown summary (if generated)
- `integration_test/junit.xml` - JUnit format for CI/CD

## Test Structure

### Files
- `app_test.dart` - Main UI flow tests (login, navigation, etc.)
- `app_auth_env_test.dart` - Environment-driven auth tests
- `product_card_test.dart` - Widget unit tests
- `run_integration_tests.sh` - Test execution script

### Helper Files
- `test_helpers.dart` (in lib/) - Test configuration utilities
- `json_to_markdown.dart` - Report converter

## Best Practices

1. **Always clean up resources** in `tearDown()`
2. **Use explicit timeouts** to prevent hanging
3. **Mock external dependencies** when possible
4. **Keep tests independent** - don't rely on test order
5. **Use descriptive test names** for easier debugging
