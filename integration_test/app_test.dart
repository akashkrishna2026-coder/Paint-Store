
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Import the iconsax package to find icons ---
import 'package:iconsax/iconsax.dart';

// Import your main app file and the pages you want to test
// These paths are correct based on your project structure.
import 'package:c_h_p/main.dart' as app;
import 'package:c_h_p/auth/login_page.dart';
import 'package:c_h_p/pages/core/home_page.dart';
import 'package:c_h_p/auth/register_page.dart';
import 'package:c_h_p/test_helpers.dart';

// Read test credentials from environment; default to requested values for convenience
const String kTestEmail = String.fromEnvironment('TEST_EMAIL', defaultValue: 'akashkrishna389@gmail.com');
const String kTestPassword = String.fromEnvironment('TEST_PASSWORD', defaultValue: 'Akash@172002');

void main() {
  // Ensure the integration test binding is initialized
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  // Configure app for testing to skip loading screens and prevent hanging
  configureForTesting();
  
  // Only run auth-dependent tests when creds are provided
  final bool shouldRunAuth = kTestEmail.isNotEmpty && kTestPassword.isNotEmpty;

  // --- Test Setup ---
  // We create robot "helpers" for each page to make our tests
  // cleaner, more readable, and more maintainable.
  late LoginPageRobot loginRobot;
  late RegisterPageRobot registerRobot;
  late HomePageRobot homePageRobot;

  // This runs before each test
  setUp(() {
    // This is a common pattern to initialize robots for each test
    // We pass the 'tester' so the robot can perform actions.
    // Note: We can't initialize them here, we do it inside testWidgets
    // This is just to show the structure.
  });

  // Clean up Firebase auth after each test to prevent resource leaks
  tearDown(() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      // Ignore errors during cleanup
    }
  });

  // Group tests related to authentication
  group('Authentication Flow Tests', () {
    // Test case for successful email/password login
    testWidgets('Login with valid email and password navigates to HomePage',
            (WidgetTester tester) async {
          // Initialize robots for this test
          loginRobot = LoginPageRobot(tester);
          homePageRobot = HomePageRobot(tester);

          // Start the app
          app.main();
          await tester.pumpAndSettle(const Duration(seconds: 10));
          
          // Wait for LoginPage to appear
          await loginRobot.waitForPageToLoad();

          // --- Test Steps (using the robot) ---
          await loginRobot.enterEmail(kTestEmail);
          await loginRobot.enterPassword(kTestPassword);
          await loginRobot.tapLoginButton();

          // --- Verification ---
          await homePageRobot.expectToBeOnPage();
          await loginRobot.expectToNotBeOnPage();
        }, skip: !shouldRunAuth); // End testWidgets

    // Test case for login failure
    testWidgets('Login with invalid password shows correct error message', (WidgetTester tester) async {
      // Initialize robots
      loginRobot = LoginPageRobot(tester);
      homePageRobot = HomePageRobot(tester);

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));
      
      // Wait for LoginPage to appear
      await loginRobot.waitForPageToLoad();

      // --- Test Steps (using the robot) ---
      await loginRobot.enterEmail(kTestEmail.isNotEmpty ? kTestEmail : 'user@example.com');
      await loginRobot.enterPassword('invalidPassword');
      await loginRobot.tapLoginButton();
      await tester.pump(const Duration(seconds: 1)); // Wait for error to appear
      await tester.pump(); // One more frame

      // --- Verification ---
      await homePageRobot.expectToNotBeOnPage();
      await loginRobot.expectToBeOnPage();
      await loginRobot.findError('Incorrect email or password. Please try again.');
    }, skip: !shouldRunAuth); // End testWidgets


    // --- Test: Page Navigation (Login -> Register -> Login) ---
    testWidgets('Navigation from Login to Register page and back', (WidgetTester tester) async {
      // Initialize robots
      loginRobot = LoginPageRobot(tester);
      registerRobot = RegisterPageRobot(tester);

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));
      
      // Wait for LoginPage to appear and animations to complete
      await loginRobot.waitForPageToLoad();

      // --- Test Steps (using the robot) ---

      // 1. Start on Login, go to Register
      await loginRobot.tapSignUpLink();

      // 2. Verify we are on Register page
      await registerRobot.expectToBeOnPage();
      await loginRobot.expectToNotBeOnPage();

      // 3. From Register, go back to Login
      await registerRobot.tapLoginLink();

      // 4. Verify we are back on Login page
      await loginRobot.expectToBeOnPage();
      await registerRobot.expectToNotBeOnPage();
    });


    // --- Test: Specific Widget UI/UX Properties ---
    testWidgets('Login page UI elements have correct styling', (WidgetTester tester) async {
      // Initialize robots
      loginRobot = LoginPageRobot(tester);

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));
      
      // Wait for LoginPage to appear and animations to complete
      await loginRobot.waitForPageToLoad();

      // --- Test Steps (using the robot) ---
      await loginRobot.expectLoginButtonHasCorrectStyle();
      await loginRobot.expectWelcomeTextIsPresent();
      await loginRobot.expectForgotPasswordIsPresent();
    });

  }); // End group
}


// -----------------------------------------------------------------
// --- PAGE OBJECT ROBOTS ---
// These classes store all the "how-to" for finding and
// interacting with widgets. This makes tests clean.
// -----------------------------------------------------------------

class LoginPageRobot {
  final WidgetTester tester;
  LoginPageRobot(this.tester);

  // --- Finders (the "how") ---
  Finder get _emailField => find.widgetWithIcon(TextFormField, Iconsax.sms);
  Finder get _passwordField => find.widgetWithIcon(TextFormField, Iconsax.lock_1);
  Finder get _loginButton => find.widgetWithText(ElevatedButton, 'Login');
  Finder get _signUpLink => find.text('Sign up');
  Finder get _forgotPasswordLink => find.text('Forgot Password?');
  Finder get _welcomeText => find.text('Welcome');
  Finder get _pageFinder => find.byType(LoginPage);

  // --- Actions (the "what") ---
  Future<void> enterEmail(String email) async {
    expect(_emailField, findsOneWidget, reason: 'Email field not found');
    await tester.enterText(_emailField, email);
    await tester.pump();
  }

  Future<void> enterPassword(String password) async {
    expect(_passwordField, findsOneWidget, reason: 'Password field not found');
    await tester.enterText(_passwordField, password);
    await tester.pump();
  }

  Future<void> tapLoginButton() async {
    expect(_loginButton, findsOneWidget, reason: 'Login button not found');
    await tester.tap(_loginButton);
    // Use staged pumps to avoid hanging
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 2)); // initial network time
    await tester.pump();
  }

  Future<void> tapSignUpLink() async {
    // Wait a bit for any remaining animations
    await tester.pump(const Duration(milliseconds: 500));
    expect(_signUpLink, findsOneWidget, reason: 'Sign up link not found');
    await tester.tap(_signUpLink);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  }
  
  Future<void> waitForPageToLoad() async {
    // Wait for LoginPage widget to be present (with retries)
    int attempts = 0;
    while (attempts < 5) {
      await tester.pump(const Duration(milliseconds: 500));
      if (tester.any(_pageFinder)) {
        break;
      }
      attempts++;
    }
    
    expect(_pageFinder, findsOneWidget, reason: 'LoginPage did not load after waiting');
    
    // Wait for login page animations to complete (1 second animation)
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump();
  }

  // --- Verifications (the "checks") ---
  Future<void> findError(String message) async {
    expect(find.text(message), findsOneWidget, reason: 'Error message "$message" not found');
  }

  Future<void> expectToBeOnPage() async {
    expect(_pageFinder, findsOneWidget, reason: 'Not on LoginPage');
  }

  Future<void> expectToNotBeOnPage() async {
    expect(_pageFinder, findsNothing, reason: 'Still on LoginPage, but should not be');
  }

  Future<void> expectLoginButtonHasCorrectStyle() async {
    final ElevatedButton buttonWidget = tester.widget(_loginButton);
    expect(buttonWidget.style?.foregroundColor?.resolve({}), Colors.white,
        reason: 'Login button text color should be white');
  }

  Future<void> expectWelcomeTextIsPresent() async {
    expect(_welcomeText, findsOneWidget, reason: '"Welcome" text not found');
  }

  Future<void> expectForgotPasswordIsPresent() async {
    expect(_forgotPasswordLink, findsOneWidget, reason: '"Forgot Password?" button not found');
  }
}


class RegisterPageRobot {
  final WidgetTester tester;
  RegisterPageRobot(this.tester);

  // --- Finders (the "how") ---
  // On the register page, the fields are plain TextFields, so
  // finding by label text is the most reliable way.
  Finder _field(String label) => find.widgetWithText(TextField, label);
  Finder get _registerButton => find.widgetWithText(ElevatedButton, 'Register');
  Finder get _loginLink => find.descendant(
    of: find.byType(RegisterPage), // Ensure it's the one on this page
    matching: find.text('Login'),
  );
  Finder get _pageFinder => find.byType(RegisterPage);
  Finder get _pageTitle => find.text('Create Account');

  // --- Actions (the "what") ---
  Future<void> enterFullName(String name) async => await tester.enterText(_field('Full Name'), name);
  Future<void> enterEmail(String email) async => await tester.enterText(_field('Email Address'), email);
  Future<void> enterPhone(String phone) async => await tester.enterText(_field('Phone Number'), phone);
  Future<void> enterAddress(String address) async => await tester.enterText(_field('Address'), address);
  Future<void> enterPassword(String password) async => await tester.enterText(_field('Password'), password);
  Future<void> enterConfirmPassword(String confirm) async => await tester.enterText(_field('Confirm Password'), confirm);

  Future<void> tapRegisterButton() async {
    expect(_registerButton, findsOneWidget, reason: 'Register button not found');
    await tester.tap(_registerButton);
    // Use pump with timeout instead of pumpAndSettle to avoid hanging
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 3)); // Wait for Firebase
    await tester.pump(); // Final frame
  }

  Future<void> tapLoginLink() async {
    expect(_loginLink, findsOneWidget, reason: 'Login link not found');
    await tester.tap(_loginLink);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
  }

  // --- Verifications (the "checks") ---
  Future<void> expectToBeOnPage() async {
    expect(_pageFinder, findsOneWidget, reason: 'Not on RegisterPage');
    expect(_pageTitle, findsOneWidget, reason: 'RegisterPage title not visible');
  }

  Future<void> expectToNotBeOnPage() async {
    expect(_pageFinder, findsNothing, reason: 'Still on RegisterPage, but should not be');
  }
}


class HomePageRobot {
  final WidgetTester tester;
  HomePageRobot(this.tester);

  // --- Finders (the "how") ---
  Finder get _pageFinder => find.byType(HomePage);

  // --- Verifications (the "checks") ---
  Future<void> expectToBeOnPage() async {
    // Wait up to 30s for HomePage to appear, capturing any SnackBar errors
    const totalWait = Duration(seconds: 30);
    const step = Duration(milliseconds: 500);
    var waited = Duration.zero;
    String? snackError;
    while (waited < totalWait) {
      await tester.pump(step);
      waited += step;
      if (tester.any(_pageFinder)) {
        break;
      }
      final snackFinder = find.byType(SnackBar);
      if (snackFinder.evaluate().isNotEmpty) {
        final bar = tester.widget<SnackBar>(snackFinder.first);
        final content = (bar.content as Text).data ?? '';
        snackError = content;
      }
    }
    if (!tester.any(_pageFinder)) {
      fail('Not on HomePage after ${totalWait.inSeconds}s.'
          '${snackError != null ? ' SnackBar: "$snackError"' : ''}');
    }
  }

  // --- FIX: Added the missing method ---
  Future<void> expectToNotBeOnPage() async {
    expect(_pageFinder, findsNothing, reason: 'Still on HomePage, but should not be');
  }
// --- END FIX ---
}

