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

class _NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoAnimationPageTransitionsBuilder();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

class _MyAppState extends State<MyApp> {
  bool? _isFirstTime;
  bool _assetsPrecached = false;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initServices();
      _precacheAppImages();
    });
    // Keep FCM registration updated with auth state
    FirebaseAuth.instance.authStateChanges().listen((user) {
      FCMService.updateForUser(user);
    });
    // Foreground: show a local notification
    FCMService.listenForegroundMessages(onMessage: (m) {
      final title = m.notification?.title ?? 'Notification';
      final body = m.notification?.body ?? '';
      final payload = m.data.isNotEmpty ? m.data.toString() : null;
      NotificationService.instance.showForegroundNotification(
          title: title, body: body, payload: payload);
    });

    // Deep-link when user taps an FCM notification from background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      NotificationService.instance.navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const NotificationsPage()),
      );
    });
  }

  Future<void> _initServices() async {
    try {
      await NotificationService.instance.init();
      await FCMService.requestPermission();
      await FCMService.updateForUser(FirebaseAuth.instance.currentUser);
    } catch (e) {
      debugPrint('Startup service init error: $e');
    }
  }

  // Precache frequently used asset images once app has a build context
  void _precacheAppImages() {
    if (_assetsPrecached) return;
    final ctx = NotificationService.instance.navigatorKey.currentContext;
    if (ctx == null) {
      // Try again on next frame if the navigator context isn't ready yet
      WidgetsBinding.instance.addPostFrameCallback((_) => _precacheAppImages());
      return;
    }
    precacheImage(const AssetImage('assets/image_b8a96a.jpg'), ctx);
    precacheImage(const AssetImage('assets/image_b8aca7.jpg'), ctx);
    precacheImage(const AssetImage('assets/image_b8b0ca.jpg'), ctx);
    _assetsPrecached = true;
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
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: _NoAnimationPageTransitionsBuilder(),
            TargetPlatform.iOS: _NoAnimationPageTransitionsBuilder(),
            TargetPlatform.linux: _NoAnimationPageTransitionsBuilder(),
            TargetPlatform.macOS: _NoAnimationPageTransitionsBuilder(),
            TargetPlatform.windows: _NoAnimationPageTransitionsBuilder(),
          },
        ),
      ),
      debugShowCheckedModeBanner: false,
      navigatorKey: NotificationService.instance.navigatorKey,
      home: _isFirstTime! ? const OnboardingScreen() : _getNextPage(),
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
