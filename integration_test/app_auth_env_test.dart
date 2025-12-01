import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:c_h_p/main.dart' as app;
import 'package:c_h_p/auth/login_page.dart';
import 'package:c_h_p/pages/core/home_page.dart';
import 'package:c_h_p/test_helpers.dart';

const String kTestEmail = String.fromEnvironment('TEST_EMAIL', defaultValue: 'akashkrishna389@gmail.com');
const String kTestPassword = String.fromEnvironment('TEST_PASSWORD', defaultValue: 'Akash@172002');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  // Configure app for testing to skip loading screens and prevent hanging
  configureForTesting();

  // If creds are not provided, skip these tests to keep CI green.
  final bool shouldRunAuth = kTestEmail.isNotEmpty && kTestPassword.isNotEmpty;

  // Clean up Firebase auth after each test to prevent resource leaks
  tearDown(() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      // Ignore errors during cleanup
    }
  });

  group('Auth Flow (env-driven)', () {
    testWidgets(
      'Login with TEST_EMAIL/TEST_PASSWORD navigates to HomePage',
      (tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 10));

        // Finders
        final emailField = find.widgetWithIcon(TextFormField, Iconsax.sms);
        final passwordField = find.widgetWithIcon(TextFormField, Iconsax.lock_1);
        final loginButton = find.widgetWithText(ElevatedButton, 'Login');

        // Actions
        expect(emailField, findsOneWidget);
        expect(passwordField, findsOneWidget);
        await tester.enterText(emailField, kTestEmail);
        await tester.pump();
        await tester.enterText(passwordField, kTestPassword);
        await tester.pump();
        await tester.tap(loginButton);

        // Wait up to 30s for navigation to HomePage, checking for SnackBar errors along the way
        const totalWait = Duration(seconds: 30);
        const step = Duration(milliseconds: 500);
        var waited = Duration.zero;
        String? snackError;
        while (waited < totalWait) {
          await tester.pump(step);
          waited += step;

          // If HomePage is found, pass
          if (find.byType(HomePage).evaluate().isNotEmpty) {
            break;
          }

          // Capture SnackBar error text if shown
          final snackFinder = find.byType(SnackBar);
          if (snackFinder.evaluate().isNotEmpty) {
            final snackBar = tester.widget<SnackBar>(snackFinder.first);
            final content = (snackBar.content as Text).data ?? '';
            snackError = content;
          }
        }

        // Final expectations with helpful failure context
        if (find.byType(HomePage).evaluate().isEmpty) {
          fail('Did not navigate to HomePage within ${totalWait.inSeconds}s.'
              '${snackError != null ? ' SnackBar: "$snackError"' : ''}');
        }
        expect(find.byType(LoginPage), findsNothing);
      },
      skip: !shouldRunAuth,
    );
  });
}
