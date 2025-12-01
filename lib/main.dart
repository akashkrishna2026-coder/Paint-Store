import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/fcm_service.dart';
import 'services/fcm_background.dart';
import 'services/notification_service.dart';
import 'pages/core/notifications_page.dart';
import 'services/recommendation_service.dart';

import 'firebase_options.dart';
import 'auth/login_page.dart';
import 'widgets/loading_screen.dart';
import 'widgets/onboarding_screen.dart';
import 'pages/core/home_page.dart';
import 'test_helpers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://smart-paint-shop-default-rtdb.firebaseio.com/',
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await FCMService.requestPermission();
  await FCMService.updateForUser(FirebaseAuth.instance.currentUser);
  await NotificationService.instance.init();

  final api = const String.fromEnvironment('RECO_API');
  if (api.isNotEmpty) {
    RecommendationService.apiBaseUrl = api;
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? _isFirstTime;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
    // Keep FCM registration updated with auth state
    FirebaseAuth.instance.authStateChanges().listen((user) {
      FCMService.updateForUser(user);
    });
    // Foreground: show a local notification
    FCMService.listenForegroundMessages(onMessage: (m) {
      final title = m.notification?.title ?? 'Notification';
      final body = m.notification?.body ?? '';
      final payload = m.data.isNotEmpty ? m.data.toString() : null;
      NotificationService.instance
          .showForegroundNotification(title: title, body: body, payload: payload);
    });

    // Deep-link when user taps an FCM notification from background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      NotificationService.instance.navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const NotificationsPage()),
      );
    });
  }

  Future<void> _checkFirstTime() async {
    // Skip onboarding in test mode
    if (skipOnboardingScreen) {
      setState(() {
        _isFirstTime = false;
      });
      return;
    }
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('isFirstTime') ?? true;

    setState(() {
      _isFirstTime = isFirstTime;
    });

    if (isFirstTime) {
      prefs.setBool('isFirstTime', false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFirstTime == null) {
      // While we check first time status, show loading
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const LoadingScreen(nextPage: SizedBox()),
      );
    }

    return MaterialApp(
      title: 'Smart Paint Shop',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      navigatorKey: NotificationService.instance.navigatorKey,
      home: LoadingScreen(
        nextPage: _isFirstTime! ? const OnboardingScreen() : _getNextPage(),
      ),
    );
  }

  Widget _getNextPage() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return const HomePage(); // Logged-in user
    } else {
      return const LoginPage(); // Not logged in
    }
  }
}
