import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:c_h_p/main.dart' as app;
import 'package:c_h_p/pages/core/home_page.dart';
import 'package:c_h_p/auth/register_page.dart';
import 'package:c_h_p/test_helpers.dart';

const String kRegName =
    String.fromEnvironment('REG_NAME', defaultValue: 'Test User');
const String kRegEmail = String.fromEnvironment('REG_EMAIL', defaultValue: '');
const String kRegPhone =
    String.fromEnvironment('REG_PHONE', defaultValue: '9999999999');
const String kRegAddress =
    String.fromEnvironment('REG_ADDRESS', defaultValue: '123 Test Street');
// Must satisfy validation: >=6 chars, includes uppercase, number, special, no leading or double spaces
const String kRegPassword =
    String.fromEnvironment('REG_PASSWORD', defaultValue: 'Aa1@1234');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  configureForTesting();

  tearDown(() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  });

  final bool hasRegCreds = kRegEmail.isNotEmpty && kRegPassword.isNotEmpty;

  group('Register Flow', () {
    testWidgets('new user registers and lands on HomePage', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Navigate from Login to Register
      final signUpLink = find.widgetWithText(TextButton, 'Sign up');
      expect(signUpLink, findsOneWidget);
      await tester.tap(signUpLink);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // On RegisterPage, fields are TextField with labels
      expect(find.byType(RegisterPage), findsOneWidget);

      Future<void> enterLabeledText(String label, String value) async {
        final finder = find.descendant(
          of: find.byType(TextField),
          matching: find.widgetWithText(InputDecorator, label),
        );
        // Fallback: match by labelText using widget predicate
        Finder textField = find.byWidgetPredicate((w) {
          if (w is TextField) {
            final d = w.decoration;
            return d?.labelText == label;
          }
          return false;
        });
        if (textField.evaluate().isEmpty && finder.evaluate().isNotEmpty) {
          textField =
              find.ancestor(of: finder.first, matching: find.byType(TextField));
        }
        expect(textField, findsOneWidget);
        await tester.enterText(textField, value);
        await tester.pump();
      }

      await enterLabeledText('Full Name', kRegName);
      await enterLabeledText('Email Address', kRegEmail);
      await enterLabeledText('Phone Number', kRegPhone);
      await enterLabeledText('Address', kRegAddress);
      await enterLabeledText('Password', kRegPassword);
      await enterLabeledText('Confirm Password', kRegPassword);

      final registerButton = find.widgetWithText(ElevatedButton, 'Register');
      expect(registerButton, findsOneWidget);
      await tester.tap(registerButton);

      // Wait for navigation
      const totalWait = Duration(seconds: 40);
      const step = Duration(milliseconds: 500);
      var waited = Duration.zero;
      String? snackError;
      while (waited < totalWait) {
        await tester.pump(step);
        waited += step;
        if (find.byType(HomePage).evaluate().isNotEmpty) {
          break;
        }
        final snackFinder = find.byType(SnackBar);
        if (snackFinder.evaluate().isNotEmpty) {
          final snackBar = tester.widget<SnackBar>(snackFinder.first);
          final content = (snackBar.content as Text).data ?? '';
          snackError = content;
        }
      }

      if (find.byType(HomePage).evaluate().isEmpty) {
        fail(
            'Registration did not navigate to HomePage within ${totalWait.inSeconds}s.'
            '${snackError != null ? ' SnackBar: "$snackError"' : ''}');
      }
    }, skip: !hasRegCreds);
  });
}
