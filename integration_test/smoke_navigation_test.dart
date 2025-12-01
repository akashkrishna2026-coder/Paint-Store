import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';

import 'package:c_h_p/main.dart' as app;
import 'package:c_h_p/test_helpers.dart';
import 'package:c_h_p/auth/login_page.dart';
import 'package:c_h_p/pages/core/home_page.dart';
import 'package:c_h_p/pages/core/cart_page.dart';
import 'package:c_h_p/pages/core/notifications_page.dart';
import 'package:c_h_p/pages/core/report_issue_page.dart';
import 'package:c_h_p/product/explore_product.dart';

// Read optional creds for auth-requiring pages
const String kTestEmail = String.fromEnvironment('TEST_EMAIL', defaultValue: '');
const String kTestPassword = String.fromEnvironment('TEST_PASSWORD', defaultValue: '');

Future<void> _loginIfCredsProvided(WidgetTester tester) async {
  if (kTestEmail.isEmpty || kTestPassword.isEmpty) return;
  // Already logged in?
  if (FirebaseAuth.instance.currentUser != null) return;

  // Expect LoginPage is visible
  final emailField = find.widgetWithIcon(TextFormField, Iconsax.sms);
  final passwordField = find.widgetWithIcon(TextFormField, Iconsax.lock_1);
  final loginButton = find.widgetWithText(ElevatedButton, 'Login');

  expect(emailField, findsOneWidget);
  expect(passwordField, findsOneWidget);
  await tester.enterText(emailField, kTestEmail);
  await tester.pump();
  await tester.enterText(passwordField, kTestPassword);
  await tester.pump();
  await tester.tap(loginButton);

  // Wait up to 30s for HomePage
  const totalWait = Duration(seconds: 30);
  const step = Duration(milliseconds: 500);
  var waited = Duration.zero;
  while (waited < totalWait) {
    await tester.pump(step);
    waited += step;
    if (find.byType(HomePage).evaluate().isNotEmpty) break;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  configureForTesting();

  tearDown(() async {
    try { await FirebaseAuth.instance.signOut(); } catch (_) {}
  });

  group('App smoke navigation', () {
    testWidgets('Launch to HomePage (login or skip)', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // If LoginPage present, either login (if creds) or tap Skip
      if (find.byType(LoginPage).evaluate().isNotEmpty) {
        if (kTestEmail.isNotEmpty && kTestPassword.isNotEmpty) {
          await _loginIfCredsProvided(tester);
        } else {
          final skipButton = find.text('Skip');
          if (skipButton.evaluate().isNotEmpty) {
            await tester.tap(skipButton);
            await tester.pumpAndSettle(const Duration(seconds: 5));
          }
        }
      }

      expect(find.byType(HomePage), findsOneWidget, reason: 'HomePage should be visible');
    });

    testWidgets('Navigate to Explore via bottom nav', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));
      // Reach home (login or skip)
      if (find.byType(LoginPage).evaluate().isNotEmpty) {
        if (kTestEmail.isNotEmpty && kTestPassword.isNotEmpty) {
          await _loginIfCredsProvided(tester);
        } else {
          final skipButton = find.text('Skip');
          if (skipButton.evaluate().isNotEmpty) {
            await tester.tap(skipButton);
            await tester.pumpAndSettle(const Duration(seconds: 5));
          }
        }
      }

      // Tap Explore label in NavigationBar
      final exploreTab = find.text('Explore');
      expect(exploreTab, findsOneWidget);
      await tester.tap(exploreTab);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(ExploreProductPage), findsOneWidget);
    });

    testWidgets('Open Notifications from AppBar', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));
      if (find.byType(LoginPage).evaluate().isNotEmpty) {
        if (kTestEmail.isNotEmpty && kTestPassword.isNotEmpty) {
          await _loginIfCredsProvided(tester);
        } else {
          final skipButton = find.text('Skip');
          if (skipButton.evaluate().isNotEmpty) {
            await tester.tap(skipButton);
            await tester.pumpAndSettle(const Duration(seconds: 5));
          }
        }
      }

      // Tap bell icon
      final notifIcon = find.byIcon(Iconsax.notification);
      expect(notifIcon, findsOneWidget);
      await tester.tap(notifIcon);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Either NotificationsPage or Login Required dialog if not authed
      if (kTestEmail.isNotEmpty && kTestPassword.isNotEmpty) {
        expect(find.byType(NotificationsPage), findsOneWidget);
      } else {
        expect(find.text('Login Required'), findsOneWidget);
        // Dismiss
        final cancel = find.text('Cancel');
        if (cancel.evaluate().isNotEmpty) {
          await tester.tap(cancel);
          await tester.pumpAndSettle(const Duration(seconds: 1));
        }
      }
    });

    testWidgets('Navigate to Cart via bottom nav', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));
      if (find.byType(LoginPage).evaluate().isNotEmpty) {
        if (kTestEmail.isNotEmpty && kTestPassword.isNotEmpty) {
          await _loginIfCredsProvided(tester);
        } else {
          final skipButton = find.text('Skip');
          if (skipButton.evaluate().isNotEmpty) {
            await tester.tap(skipButton);
            await tester.pumpAndSettle(const Duration(seconds: 5));
          }
        }
      }

      final cartTab = find.text('Cart');
      expect(cartTab, findsOneWidget);
      await tester.tap(cartTab);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      if (kTestEmail.isNotEmpty && kTestPassword.isNotEmpty) {
        expect(find.byType(CartPage), findsOneWidget);
      } else {
        expect(find.text('Login Required'), findsOneWidget);
      }
    });

    testWidgets('Navigate to Report via bottom nav', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));
      if (find.byType(LoginPage).evaluate().isNotEmpty) {
        if (kTestEmail.isNotEmpty && kTestPassword.isNotEmpty) {
          await _loginIfCredsProvided(tester);
        } else {
          final skipButton = find.text('Skip');
          if (skipButton.evaluate().isNotEmpty) {
            await tester.tap(skipButton);
            await tester.pumpAndSettle(const Duration(seconds: 5));
          }
        }
      }

      final reportTab = find.text('Report');
      expect(reportTab, findsOneWidget);
      await tester.tap(reportTab);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      if (kTestEmail.isNotEmpty && kTestPassword.isNotEmpty) {
        expect(find.byType(ReportIssuePage), findsOneWidget);
      } else {
        expect(find.text('Login Required'), findsOneWidget);
      }
    });
  });
}
