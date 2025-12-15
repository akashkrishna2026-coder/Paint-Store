import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:c_h_p/main.dart' as app;
import 'package:c_h_p/auth/login_page.dart';
import 'package:c_h_p/pages/core/home_page.dart';
import 'package:c_h_p/test_helpers.dart';

const String kLoginEmail =
    String.fromEnvironment('TEST_EMAIL', defaultValue: '');
const String kLoginPassword =
    String.fromEnvironment('TEST_PASSWORD', defaultValue: '');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  configureForTesting();

  tearDown(() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  });

  final bool hasCreds = kLoginEmail.isNotEmpty && kLoginPassword.isNotEmpty;

  group('Login Flow', () {
    testWidgets('valid credentials navigate to HomePage', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));

      final emailField = find.widgetWithIcon(TextFormField, Iconsax.sms);
      final passwordField = find.widgetWithIcon(TextFormField, Iconsax.lock_1);
      final loginButton = find.widgetWithText(ElevatedButton, 'Login');

      expect(emailField, findsOneWidget);
      expect(passwordField, findsOneWidget);

      await tester.enterText(emailField, kLoginEmail);
      await tester.pump();
      await tester.enterText(passwordField, kLoginPassword);
      await tester.pump();
      await tester.tap(loginButton);

      const totalWait = Duration(seconds: 30);
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
        fail('Did not navigate to HomePage within ${totalWait.inSeconds}s.'
            '${snackError != null ? ' SnackBar: "$snackError"' : ''}');
      }
      expect(find.byType(LoginPage), findsNothing);
    }, skip: !hasCreds);
  });
}
