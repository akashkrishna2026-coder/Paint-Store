import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:iconsax/iconsax.dart';
import 'package:c_h_p/main.dart' as app;
import 'package:c_h_p/auth/login_page.dart';
import 'package:c_h_p/pages/core/home_page.dart';

const String kTestEmail = String.fromEnvironment('TEST_EMAIL', defaultValue: '');
const String kTestPassword = String.fromEnvironment('TEST_PASSWORD', defaultValue: '');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // If creds are not provided, skip these tests to keep CI green.
  final bool shouldRunAuth = kTestEmail.isNotEmpty && kTestPassword.isNotEmpty;

  group('Auth Flow (env-driven)', () {
    testWidgets(
      'Login with TEST_EMAIL/TEST_PASSWORD navigates to HomePage',
      (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Finders
        final emailField = find.widgetWithIcon(TextFormField, Iconsax.sms);
        final passwordField = find.widgetWithIcon(TextFormField, Iconsax.lock_1);
        final loginButton = find.widgetWithText(ElevatedButton, 'Login');

        // Actions
        expect(emailField, findsOneWidget);
        expect(passwordField, findsOneWidget);
        await tester.enterText(emailField, kTestEmail);
        await tester.enterText(passwordField, kTestPassword);
        await tester.tap(loginButton);
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Verify home
        expect(find.byType(HomePage), findsOneWidget);
        expect(find.byType(LoginPage), findsNothing);
      },
      skip: !shouldRunAuth,
    );
  });
}
