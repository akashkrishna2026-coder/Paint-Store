import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:c_h_p/main.dart' as app;
import 'package:c_h_p/pages/core/home_page.dart';
import 'package:c_h_p/auth/personal_info_page.dart';
import 'package:c_h_p/test_helpers.dart';

const String kTestEmail =
    String.fromEnvironment('TEST_EMAIL', defaultValue: '');
const String kTestPassword =
    String.fromEnvironment('TEST_PASSWORD', defaultValue: '');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  configureForTesting();

  tearDown(() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  });

  final bool hasCreds = kTestEmail.isNotEmpty && kTestPassword.isNotEmpty;

  group('Personal Info Flow', () {
    testWidgets('navigate to PersonalInfoPage from Home drawer',
        (tester) async {
      // Start app and login first
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));

      if (find.byType(HomePage).evaluate().isEmpty) {
        final emailField = find.widgetWithIcon(TextFormField, Iconsax.sms);
        final passwordField =
            find.widgetWithIcon(TextFormField, Iconsax.lock_1);
        final loginButton = find.widgetWithText(ElevatedButton, 'Login');

        expect(emailField, findsOneWidget);
        expect(passwordField, findsOneWidget);
        await tester.enterText(emailField, kTestEmail);
        await tester.pump();
        await tester.enterText(passwordField, kTestPassword);
        await tester.pump();
        await tester.tap(loginButton);

        // Wait for HomePage
        const totalWait = Duration(seconds: 30);
        const step = Duration(milliseconds: 500);
        var waited = Duration.zero;
        while (waited < totalWait) {
          await tester.pump(step);
          waited += step;
          if (find.byType(HomePage).evaluate().isNotEmpty) break;
        }
        expect(find.byType(HomePage), findsOneWidget);
      }

      // Open Drawer
      final openDrawer = find.byTooltip('Open navigation menu');
      expect(openDrawer, findsOneWidget);
      await tester.tap(openDrawer);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tap Profile item
      final profileTile = find.widgetWithText(ListTile, 'Profile');
      expect(profileTile, findsOneWidget);
      await tester.tap(profileTile);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify PersonalInfoPage
      expect(find.byType(PersonalInfoPage), findsOneWidget);
    }, skip: !hasCreds);
  });
}
